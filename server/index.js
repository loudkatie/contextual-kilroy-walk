const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT || 8787);
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';
const DATA_FILE = path.join(__dirname, 'data.json');
const MAX_MESSAGES = 18;

const SYSTEM_PROMPT = `You are Tink, a proactive spatial AI agent. You never wait for prompts. You do not show a chat UI. You whisper only when relevant. Return JSON only.\n\nRules:\n- No chat or long text. Short, whispery phrasing.\n- You must return a strict JSON object with fields: status, explanation, eligibility, consentState, moment, plan.\n- status is one of: triggered, missingLocation, outsideZone, noMatch.\n- consentState is one of: idle, awaiting, granted, denied, coolingDown.\n- If status is triggered, include moment and plan. Otherwise moment can be null.\n- Moment must include: id, title, subtitle, whisperAudioKey, hostLine, detail, actions, requiresConsent, gatingToken, trigger, manualTriggerID, priority, cooldownSeconds, metadata.\n- Actions must include: id, title, kind, style, payload, iconName.\n- Trigger must include: kind and value. Use kind "manual" with value "ai" for AI-triggered moments.\n`;

const FALLBACK_MOMENTS = {
  arrival: {
    id: 'frontier.arrival',
    title: 'Welcome to Frontier Tower',
    subtitle: 'Market St entrance',
    whisperAudioKey: 'psst_welcome_frontier',
    hostLine: 'Tink: You are at the Frontier entrance. Want the quick orientation?',
    detail: 'Wave hello, grab your badge, and the lobby guide will flag the Kilroy liaison.',
    actions: [
      {
        id: 'arrival.start',
        title: 'Start walkthrough',
        kind: 'openCard',
        style: 'primary',
        payload: 'arrival_brief',
        iconName: 'figure.walk.motion'
      },
      {
        id: 'arrival.skip',
        title: 'Not now',
        kind: 'acknowledge',
        style: 'secondary',
        payload: null,
        iconName: 'clock'
      }
    ],
    requiresConsent: true,
    gatingToken: null,
    trigger: { kind: 'manual', value: 'ai' },
    manualTriggerID: 'moment.arrival',
    priority: 100,
    cooldownSeconds: 120,
    metadata: { poi: 'frontier_arrival' }
  },
  coffee: {
    id: 'frontier.coffee',
    title: 'Need a quiet nook?',
    subtitle: 'Steep + Brew',
    whisperAudioKey: 'psst_drop_here',
    hostLine: 'Tink: There is a calm coffee perch nearby. Want the pin?',
    detail: 'We marked a bench tucked away from Market Street wind. Great for a prep reset.',
    actions: [
      {
        id: 'coffee.navigate',
        title: 'Guide me there',
        kind: 'openURL',
        style: 'primary',
        payload: 'maps://?ll=37.79063,-122.40182',
        iconName: 'mappin.and.ellipse'
      },
      {
        id: 'coffee.skip',
        title: 'I am good',
        kind: 'acknowledge',
        style: 'secondary',
        payload: null,
        iconName: null
      }
    ],
    requiresConsent: true,
    gatingToken: null,
    trigger: { kind: 'manual', value: 'ai' },
    manualTriggerID: 'moment.coffee',
    priority: 80,
    cooldownSeconds: 180,
    metadata: { poi: 'frontier_coffee' }
  },
  drop: {
    id: 'frontier.drop',
    title: 'Frontier drop unlocked',
    subtitle: 'Sky Lobby briefing',
    whisperAudioKey: 'psst_want_to_open',
    hostLine: 'Tink: Kilroy left a media drop upstairs. Want me to open it?',
    detail: 'Requires the Arrival token. We will keep the link warm for 10 minutes after consent.',
    actions: [
      {
        id: 'drop.open',
        title: 'Open drop',
        kind: 'openDrop',
        style: 'primary',
        payload: 'kilroy.frontier.sky',
        iconName: null
      },
      {
        id: 'drop.later',
        title: 'Save for later',
        kind: 'acknowledge',
        style: 'subtle',
        payload: null,
        iconName: null
      }
    ],
    requiresConsent: true,
    gatingToken: 'arrival',
    trigger: { kind: 'manual', value: 'ai' },
    manualTriggerID: 'moment.drop',
    priority: 90,
    cooldownSeconds: 240,
    metadata: { poi: 'frontier_drop_corner', drop_id: 'kilroy.frontier.sky' }
  }
};

function loadStore() {
  if (!fs.existsSync(DATA_FILE)) {
    return {};
  }
  try {
    return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  } catch (error) {
    return {};
  }
}

function saveStore(store) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2));
}

function jsonResponse(res, status, payload) {
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  });
  res.end(JSON.stringify(payload));
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => {
      data += chunk;
    });
    req.on('end', () => {
      if (!data) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(data));
      } catch (error) {
        reject(error);
      }
    });
  });
}

function buildFallbackResponse(manualID) {
  let moment = FALLBACK_MOMENTS.arrival;
  if (manualID === 'moment.coffee') moment = FALLBACK_MOMENTS.coffee;
  if (manualID === 'moment.drop') moment = FALLBACK_MOMENTS.drop;

  return {
    status: 'triggered',
    explanation: 'Fallback moment (no AI key configured).',
    eligibility: true,
    consentState: 'awaiting',
    moment,
    plan: {
      momentID: moment.id,
      title: moment.title,
      whisperAudioKey: moment.whisperAudioKey,
      hostLine: moment.hostLine,
      detail: moment.detail,
      primaryAction: moment.actions[0],
      secondaryAction: moment.actions[1] || null,
      source: 'fallback'
    }
  };
}

function buildUserMessage(body) {
  return {
    context: body.context,
    memory: {
      likedCount: (body.memory && body.memory.likedDrops ? body.memory.likedDrops.length : 0),
      ignoredCount: (body.memory && body.memory.ignoredDrops ? body.memory.ignoredDrops.length : 0),
      permissionTokens: body.memory && body.memory.permissionTokens ? body.memory.permissionTokens : []
    },
    recentEvents: body.recentEvents || [],
    manualID: body.manualID || null,
    timestamp: body.timestamp || new Date().toISOString()
  };
}

async function callOpenAI(messages) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${OPENAI_API_KEY}`
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      response_format: { type: 'json_object' },
      temperature: 0.4,
      messages
    })
  });

  const data = await response.json();
  if (!response.ok) {
    const message = data && data.error ? data.error.message : 'OpenAI error';
    throw new Error(message);
  }

  const content = data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content;
  if (!content) {
    throw new Error('Missing OpenAI response');
  }

  return JSON.parse(content);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    res.end();
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    jsonResponse(res, 200, { status: 'ok', model: OPENAI_MODEL });
    return;
  }

  if (req.method === 'POST' && req.url === '/agent/plan') {
    let body;
    try {
      body = await parseBody(req);
    } catch (error) {
      jsonResponse(res, 400, { error: 'Invalid JSON payload.' });
      return;
    }

    if (!body.contextualID) {
      jsonResponse(res, 400, { error: 'Missing contextualID.' });
      return;
    }

    if (!OPENAI_API_KEY) {
      jsonResponse(res, 200, buildFallbackResponse(body.manualID));
      return;
    }

    const store = loadStore();
    const record = store[body.contextualID] || { messages: [] };

    const userPayload = buildUserMessage(body);
    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...record.messages,
      { role: 'user', content: JSON.stringify(userPayload) }
    ].slice(-MAX_MESSAGES);

    try {
      const agentReply = await callOpenAI(messages);
      record.messages = messages.concat({ role: 'assistant', content: JSON.stringify(agentReply) }).slice(-MAX_MESSAGES);
      store[body.contextualID] = record;
      saveStore(store);
      jsonResponse(res, 200, agentReply);
    } catch (error) {
      jsonResponse(res, 200, buildFallbackResponse(body.manualID));
    }
    return;
  }

  jsonResponse(res, 404, { error: 'Not found' });
});

server.listen(PORT, () => {
  console.log(`Contextual AI server listening on ${PORT}`);
});
