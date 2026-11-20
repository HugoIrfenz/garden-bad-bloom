// Room coordination and WebRTC signaling only. Combat runs on a player's phone.
// TURN key and API token are Worker secrets and are never embedded in the game.
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const ROOM_CODE = /^[A-HJ-NP-Z2-9]{6}$/;
const MAX_PLAYERS = 5;
const WEAPONS = [
  ['lilyblade', 'royal_cleaver', 'morning_promise'],
  ['rosebound_grimoire', 'black_margin', 'moonquill_staff'],
  ['orchid_gauntlets', 'pocket_thunder', 'tiny_hammerfists'],
  ['camellia_longbow', 'ribbon_string', 'hollowglass_bow', 'snarewood_bow'],
  ['iris_twin_daggers', 'palette_knives', 'clockface_shank'],
  ['hammer_axe'], ['triune_light_focus'], ['luna_pistol', 'graveglass_pistol']
];
const SIGNATURE_RELICS = ['', 'rose_lens', 'orchid_spring', 'camellia_ribbon', 'iris_dice', 'temper_bell', 'threefold_prism', 'moonlit_cartridge'];
const canEquipRelic = (hero, id) => id === '' || id === 'angela_wedding_ring' || id === 'last_teaspoon'
  || (id === 'glass_eyelash' && [0, 2, 3, 4, 7].includes(hero)) || (id !== '' && id === SIGNATURE_RELICS[hero]);
const REJOIN_MS = 60_000;
const MAX_MESSAGE = 32_768;
const GAME_PACKET_HEADER = 6;
const MAX_GAME_PACKET = 1024 * 1024 + GAME_PACKET_HEADER;
const GAME_BYTES_PER_SECOND = 4 * 1024 * 1024;
const GAME_PACKETS_PER_SECOND = 100;
// Small ceiling for a private friends-only playtest. It limits the number of
// credentials, not bytes: Cloudflare's relay can still bill for overages.
const MONTHLY_RELAY_CREDENTIALS = 64;
const RELAY_BUDGET_STORAGE_KEY = 'relay-budget-v2';
const RELAY_CREDENTIAL_SECONDS = 10_800;
const encoder = new TextEncoder();
const json = (body, status = 200) => Response.json(body, { status, headers: { 'Cache-Control': 'no-store' } });
const randomHex = (size) => [...crypto.getRandomValues(new Uint8Array(size))].map(n => n.toString(16).padStart(2, '0')).join('');
const hash = async value => [...new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(value)))].map(n => n.toString(16).padStart(2, '0')).join('');
const nameIsValid = name => typeof name === 'string' && name.trim().length > 0 && name.trim().length <= 24 && !/[\r\n\u0000-\u001f]/.test(name);
const newCode = () => [...crypto.getRandomValues(new Uint8Array(6))].map(n => ALPHABET[n % ALPHABET.length]).join('');
const newPeerId = players => {
  let id;
  do { id = (crypto.getRandomValues(new Uint32Array(1))[0] & 0x7fffffff); }
  while (id < 2 || Object.values(players).some(p => p.peerId === id));
  return id;
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'POST' && url.pathname === '/rooms') {
      let body;
      try { body = await request.json(); } catch { return json({ error: 'Invalid request.' }, 400); }
      if (!nameIsValid(body.username)) return json({ error: 'Enter a name of up to 24 characters.' }, 400);
      for (let i = 0; i < 8; i++) {
        const code = newCode();
        const stub = env.GARDENS.get(env.GARDENS.idFromName(code));
        const response = await stub.fetch('https://garden.internal/init', {
          method: 'POST', headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ code, username: body.username.trim() })
        });
        if (response.status !== 409) return response;
      }
      return json({ error: 'Could not create a room. Try again.' }, 503);
    }
    const match = /^\/rooms\/([^/]+)\/ws$/.exec(url.pathname);
    if (!match || !ROOM_CODE.test(match[1]) || request.method !== 'GET') return json({ error: 'Not found.' }, 404);
    if ((request.headers.get('Upgrade') || '').toLowerCase() !== 'websocket') return json({ error: 'WebSocket required.' }, 426);
    return env.GARDENS.get(env.GARDENS.idFromName(match[1])).fetch(request);
  }
};

export class GardenRoom {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.env = env;
    this.messageQueue = Promise.resolve();
    this.gameRoom = null;
    this.gameRates = new Map();
  }

  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === 'POST' && url.pathname === '/reserve-relay') {
      return this.ctx.blockConcurrencyWhile(async () => {
        const month = new Date().toISOString().slice(0, 7);
        let budget = await this.ctx.storage.get(RELAY_BUDGET_STORAGE_KEY);
        if (!budget || budget.month !== month) budget = { month, count: 0 };
        if (budget.count >= MONTHLY_RELAY_CREDENTIALS) return json({ error: 'Monthly relay limit reached.' }, 429);
        budget.count++;
        await this.ctx.storage.put(RELAY_BUDGET_STORAGE_KEY, budget);
        return new Response(null, { status: 204 });
      });
    }
    if (request.method === 'POST' && url.pathname === '/init') {
      const existing = await this.ctx.storage.get('room');
      if (existing && Date.now() - existing.touched < 86_400_000) return json({ error: 'Room already exists.' }, 409);
      const body = await request.json();
      if (!ROOM_CODE.test(body.code) || !nameIsValid(body.username)) return json({ error: 'Invalid room.' }, 400);
      const token = randomHex(32), id = randomHex(16);
      const player = { id, peerId: newPeerId({}), tokenHash: await hash(token), username: body.username.trim(), hero: -1,
        ready: false, relic: '', weapon: '', alive: true, connected: false, departed: false, deadline: Date.now() + REJOIN_MS };
      const room = { code: body.code, phase: 'lobby', host: id, epoch: 0, players: { [id]: player }, touched: Date.now() };
      await this.ctx.storage.put('room', room);
      await this.scheduleDeadline(room);
      return json({ code: body.code, token, id }, 201);
    }
    if ((request.headers.get('Upgrade') || '').toLowerCase() !== 'websocket') return json({ error: 'WebSocket required.' }, 426);
    const room = await this.ctx.storage.get('room');
    if (!room) return json({ error: 'Room not found.' }, 404);
    if (this.ctx.getWebSockets().length >= MAX_PLAYERS * 2) return json({ error: 'Room is busy.' }, 429);
    const pair = new WebSocketPair();
    this.ctx.acceptWebSocket(pair[1]);
    pair[1].serializeAttachment({ id: '', lastIce: 0 });
    return new Response(null, { status: 101, webSocket: pair[0] });
  }

  webSocketMessage(ws, message) {
    // Serialize room mutations across awaited cryptographic operations.
    const pending = this.messageQueue.then(() => this.handleMessage(ws, message));
    this.messageQueue = pending.catch(() => {});
    return pending;
  }

  async handleMessage(ws, message) {
    if (message instanceof ArrayBuffer) return this.forwardGamePacket(ws, message);
    this.gameRoom = null;
    if (typeof message !== 'string' || encoder.encode(message).byteLength > MAX_MESSAGE) return ws.close(1009, 'Message too large.');
    let data;
    try { data = JSON.parse(message); } catch { return ws.close(1003, 'Invalid message.'); }
    if (!data || typeof data !== 'object' || Array.isArray(data)) return ws.close(1003, 'Invalid message.');
    const room = await this.ctx.storage.get('room');
    if (!room) return ws.close(1008, 'Room expired.');
    const attachment = ws.deserializeAttachment() || { id: '', lastIce: 0 };
    if (!attachment.id) return this.authenticate(ws, attachment, room, data);
    const player = room.players[attachment.id];
    if (!player || player.departed || !player.connected) return ws.close(1008, 'Session expired.');
    const type = String(data.type || '');
    room.touched = Date.now();
    if (type === 'game_transport_ready' && room.phase === 'playing') {
      if (player.roomSocket === true) return;
      player.roomSocket = true;
      await this.ctx.storage.put('room', room);
      return;
    }
    if (type === 'game_transport_fallback' && room.phase === 'playing') {
      if (room.transport === 'room-socket') return;
      const party = Object.values(room.players).filter(p => p.connected && !p.departed);
      if (party.length < 2 || party.some(p => p.roomSocket !== true)) {
        return this.send(ws, { type: 'error', message: 'Everyone needs the updated co-op build to use the fallback.' });
      }
      room.transport = 'room-socket';
      await this.ctx.storage.put('room', room);
      this.publish(room);
      return;
    }
    if (type === 'signal') {
      const target = room.players[data.to];
      if (!target || !target.connected || target.departed || target.id === player.id || !['offer', 'answer', 'candidate'].includes(data.kind)) return;
      if (typeof data.payload !== 'object' || data.payload === null) return;
      this.sendTo(target.id, { type: 'signal', from: player.id, kind: data.kind, payload: data.payload, epoch: room.epoch });
      return;
    }
    if (type === 'ice') {
      if (Date.now() - Number(attachment.lastIce || 0) < 60_000) return this.send(ws, { type: 'error', message: 'Please wait before requesting new relay credentials.' });
      attachment.lastIce = Date.now(); ws.serializeAttachment(attachment);
      return this.sendIce(ws, player.id);
    }
    if (type === 'select' && room.phase === 'lobby') {
      if (!Number.isInteger(data.hero) || data.hero < 0 || data.hero >= 8 || typeof data.ready !== 'boolean') return;
      if (player.ready && data.hero !== player.hero) return;
      if (Object.values(room.players).some(p => p.id !== player.id && !p.departed && p.hero === data.hero)) return this.send(ws, { type: 'error', message: 'That heroine is already selected.' });
      if (player.hero !== data.hero) {
        player.relic = '';
        player.weapon = WEAPONS[data.hero][0];
      }
      player.hero = data.hero; player.ready = data.ready;
    } else if (type === 'prepare' && room.phase === 'lobby' && !player.ready) {
      if (!Number.isInteger(player.hero) || player.hero < 0 || player.hero >= WEAPONS.length ||
          typeof data.weapon !== 'string' || !WEAPONS[player.hero].includes(data.weapon) ||
          typeof data.relic !== 'string' || !canEquipRelic(player.hero, data.relic)) return;
      player.weapon = data.weapon; player.relic = data.relic;
    } else if (type === 'life' && room.phase === 'playing' && player.id === room.host) {
      const target = room.players[data.player];
      if (!target || target.departed || typeof data.alive !== 'boolean' || (data.alive && !target.connected)) return;
      target.alive = data.alive;
      if (!target.connected && !target.alive) target.deadline = 0;
    } else if (type === 'start' && room.phase === 'lobby' && player.id === room.host) {
      const participants = Object.values(room.players).filter(p => !p.departed);
      if (participants.length < 2 || participants.length > MAX_PLAYERS || participants.some(p => !p.connected || !p.ready || p.hero < 0)) return;
      room.phase = 'playing';
      room.runSeed = crypto.getRandomValues(new Uint32Array(1))[0];
      room.runId = randomHex(16);
    } else if (type === 'leave') {
      player.departed = true; player.connected = false; player.deadline = 0;
      ws.serializeAttachment({ id: '', lastIce: 0 });
      this.electHost(room);
      await this.ctx.storage.put('room', room); await this.scheduleDeadline(room); this.publish(room);
      this.send(ws, { type: 'left' });
      return ws.close(1000, 'Left room.');
    } else if (type === 'ping') {
      return this.send(ws, { type: 'pong' });
    } else return;
    await this.ctx.storage.put('room', room);
    if (type === 'life') await this.scheduleDeadline(room);
    this.publish(room);
  }

  async forwardGamePacket(ws, packet) {
    if (packet.byteLength <= GAME_PACKET_HEADER || packet.byteLength > MAX_GAME_PACKET) return;
    const id = ws.deserializeAttachment()?.id;
    if (!id) return;
    const room = this.gameRoom ??= await this.ctx.storage.get('room');
    if (room?.phase !== 'playing' || room.transport !== 'room-socket') return;
    const sender = room.players[id];
    if (!sender?.connected || sender.departed || sender.roomSocket !== true) return;

    const seconds = Math.floor(Date.now() / 1000);
    let rate = this.gameRates.get(id);
    if (!rate || rate.seconds !== seconds) {
      rate = { seconds, bytes: 0, packets: 0 };
      this.gameRates.set(id, rate);
    }
    rate.bytes += packet.byteLength;
    rate.packets++;
    if (rate.bytes > GAME_BYTES_PER_SECOND || rate.packets > GAME_PACKETS_PER_SECOND) return;

    const header = new DataView(packet);
    const target = header.getInt32(0, true);
    if (header.getUint8(4) > 2) return;
    header.setInt32(0, sender.peerId, true);
    for (const recipient of this.ctx.getWebSockets()) {
      const key = recipient.deserializeAttachment()?.id;
      const member = key && room.players[key];
      if (!member?.connected || member.departed || member.roomSocket !== true || key === id) continue;
      if (target > 0 && member.peerId !== target) continue;
      if (target < 0 && member.peerId === -target) continue;
      try { recipient.send(packet); } catch { /* Closing connection. */ }
    }
  }

  async authenticate(ws, attachment, room, data) {
    const now = Date.now();
    for (const p of Object.values(room.players)) if (!p.connected && !p.departed && p.alive !== false && p.deadline <= now) p.departed = true;
    let player, token;
    if (data.type === 'auth' && typeof data.token === 'string' && /^[0-9a-f]{64}$/.test(data.token)) {
      const digest = await hash(data.token);
      player = Object.values(room.players).find(p => p.tokenHash === digest && !p.departed && (p.connected || p.alive === false || p.deadline > now));
    } else if (data.type === 'join' && room.phase === 'lobby' && nameIsValid(data.username)) {
      if (Object.values(room.players).filter(p => !p.departed).length >= MAX_PLAYERS) return ws.close(1008, 'Room full.');
      token = randomHex(32); const id = randomHex(16);
      player = { id, peerId: newPeerId(room.players), tokenHash: await hash(token), username: data.username.trim(), hero: -1, ready: false, relic: '', weapon: '', alive: true,
        connected: false, departed: false, deadline: now + REJOIN_MS };
      room.players[id] = player;
    }
    if (!player) return ws.close(1008, 'Could not join or rejoin.');
    // A mobile app can die without its old socket closing promptly. Replace
    // that socket under the same bearer token; its eventual close must not
    // disconnect the new session.
    let replaced = false;
    for (const old of this.ctx.getWebSockets()) {
      if (old !== ws && old.deserializeAttachment()?.id === player.id) {
        old.serializeAttachment({ id: '', lastIce: 0 });
        try { old.close(1000, 'Session resumed.'); } catch { /* Already closed. */ }
        replaced = true;
      }
    }
    if (replaced && player.connected) {
      // Notify existing peers to discard their old WebRTC connection before
      // advertising the replacement. Keep the current host and epoch.
      player.connected = false;
      player.deadline = player.alive === false ? 0 : now + REJOIN_MS;
      this.publish(room);
    }
    player.connected = true; player.deadline = 0;
    attachment.id = player.id; ws.serializeAttachment(attachment);
    if (!room.host || !room.players[room.host] || !room.players[room.host].connected) this.electHost(room);
    room.touched = now;
    await this.ctx.storage.put('room', room);
    await this.scheduleDeadline(room);
    this.send(ws, { type: token ? 'joined' : 'authenticated', code: room.code, id: player.id, ...(token ? { token } : {}) });
    this.publish(room);
  }

  webSocketClose(ws) { return this.queueDisconnect(ws); }
  webSocketError(ws) { return this.queueDisconnect(ws); }
  queueDisconnect(ws) {
    const pending = this.messageQueue.then(() => this.disconnect(ws));
    this.messageQueue = pending.catch(() => {});
    return pending;
  }
  async disconnect(ws) {
    this.gameRoom = null;
    this.gameRates.delete(ws.deserializeAttachment()?.id);
    const { id } = ws.deserializeAttachment() || {};
    if (!id) return;
    ws.serializeAttachment({ id: '', lastIce: 0 });
    const room = await this.ctx.storage.get('room');
    const player = room?.players[id];
    if (!player || !player.connected) return;
    player.connected = false; player.deadline = player.alive === false ? 0 : Date.now() + REJOIN_MS;
    this.electHost(room); room.touched = Date.now();
    await this.ctx.storage.put('room', room); await this.scheduleDeadline(room); this.publish(room);
  }

  async scheduleDeadline(room) {
    const deadlines = Object.values(room.players)
      .filter(p => !p.connected && !p.departed && p.alive !== false && p.deadline > 0)
      .map(p => p.deadline);
    if (deadlines.length) await this.ctx.storage.setAlarm(Math.min(...deadlines));
    else await this.ctx.storage.deleteAlarm();
  }

  alarm() {
    const pending = this.messageQueue.then(async () => {
      this.gameRoom = null;
      const room = await this.ctx.storage.get('room');
      if (!room) return;
      const now = Date.now();
      let changed = false;
      for (const p of Object.values(room.players)) {
        if (!p.connected && !p.departed && p.alive !== false && p.deadline > 0 && p.deadline <= now) {
          p.departed = true; changed = true;
        }
      }
      if (changed) {
        this.electHost(room);
        await this.ctx.storage.put('room', room);
        this.publish(room);
      }
      await this.scheduleDeadline(room);
    });
    this.messageQueue = pending.catch(() => {});
    return pending;
  }

  electHost(room) {
    const old = room.host;
    if (old && room.players[old]?.connected && !room.players[old].departed) return;
    const next = Object.values(room.players).find(p => p.connected && !p.departed);
    room.host = next?.id || '';
    if (room.host !== old) room.epoch++;
  }
  send(ws, data) { try { ws.send(JSON.stringify(data)); } catch { /* Closing connection. */ } }
  sendTo(id, data) { for (const ws of this.ctx.getWebSockets()) if (ws.deserializeAttachment()?.id === id) this.send(ws, data); }
  publish(room) {
    const players = Object.values(room.players).filter(p => !p.departed).map(({ id, peerId, username, hero, ready, relic, weapon, alive, connected, deadline }) => ({ id, peerId, username, hero, ready, relic, weapon, alive: alive !== false, connected, deadline }));
    const state = { type: 'room', code: room.code, host: room.host, epoch: room.epoch, phase: room.phase, players, runSeed: room.runSeed ?? null, runId: room.runId ?? '', transport: room.transport ?? 'webrtc' };
    for (const ws of this.ctx.getWebSockets()) if (ws.deserializeAttachment()?.id) this.send(ws, state);
  }
  async sendIce(ws, playerId) {
    const fallback = reason => this.send(ws, {
      type: 'ice', iceServers: [{ urls: ['stun:stun.cloudflare.com:3478'] }],
      relayAvailable: false, relayReason: reason
    });
    if (!this.env.TURN_KEY_ID || !this.env.TURN_API_TOKEN) return fallback('not-configured');
    try {
      const cacheKey = `relay:${playerId}`;
      const cached = await this.ctx.storage.get(cacheKey);
      if (cached && cached.expiresAt > Date.now() + 5 * 60_000) {
        return this.send(ws, { type: 'ice', iceServers: cached.iceServers, relayAvailable: true });
      }

      // The monthly budget is for newly issued credentials. Re-authentication
      // of the same player in this room can reuse a still-valid allocation key.
      const budget = this.env.GARDENS.get(this.env.GARDENS.idFromName('__relay_budget_v1'));
      const reservation = await budget.fetch('https://garden.internal/reserve-relay', { method: 'POST' });
      if (!reservation.ok) {
        const rejection = await reservation.json().catch(() => null);
        if (reservation.status === 429 && rejection?.error === 'Monthly relay limit reached.') {
          return fallback('budget-exhausted');
        }
        console.warn('Relay budget service rejected reservation', reservation.status);
        return fallback('budget-unavailable');
      }
      const response = await fetch(`https://rtc.live.cloudflare.com/v1/turn/keys/${encodeURIComponent(this.env.TURN_KEY_ID)}/credentials/generate-ice-servers`, {
        method: 'POST', headers: { authorization: `Bearer ${this.env.TURN_API_TOKEN}`, 'content-type': 'application/json' },
        body: JSON.stringify({ ttl: RELAY_CREDENTIAL_SECONDS })
      });
      if (!response.ok) return fallback('provider-unavailable');
      const data = await response.json();
      if (!Array.isArray(data.iceServers)) return fallback('provider-unavailable');
      await this.ctx.storage.put(cacheKey, {
        expiresAt: Date.now() + RELAY_CREDENTIAL_SECONDS * 1000, iceServers: data.iceServers
      });
      this.send(ws, { type: 'ice', iceServers: data.iceServers, relayAvailable: true });
    } catch {
      fallback('provider-unavailable');
    }
  }
}
