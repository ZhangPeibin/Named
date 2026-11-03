(() => {
  const A = window.NamedMedia;
  const D = window.NamedData;
  const icon = A.icon;
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const interests = [['自然', 'leaf'], ['旅行', 'pin'], ['美食', 'sparkle'], ['运动', 'flag'], ['科技', 'settings'], ['艺术', 'image'], ['阅读', 'book'], ['日常生活', 'home']];
  const steps = ['兴趣', '年龄', '性别', '日常与母语'];
  const pages = {
    onboard: ['认识你', '四步轻量引导，支持跳过、返回与之后修改。'],
    home: ['Explore · 探索', '拍照、开口或输入，从真实生活开始。'],
    discover: ['发现新事物', '照片或文字开启学习，不需要先创建挑战。'],
    result: ['认识这次发现', '确认关注的事物，也可以围绕整个场景交流。'],
    word: ['词语与理解', '图片、双语理解和听读是中心，其他帮助按需展开。'],
    talk: ['自然对话', '上部人物、中部内容、底部交流操作。下划线词句可以展开。'],
    summary: ['本次交流小结', '原对话保留，个人分享沉淀为可回访的经历。'],
    world: ['Words · 词语', '跨词语和场景搜索自己的发现，进入各自的故事。'],
    'history-list': ['History · 回忆', '按场景和话题找回交流，使用同一份原始对话与经历。'],
    connections: ['一个词的个人世界', '发现、交流、知识、历史分别组织，并且彼此连接。'],
    history: ['完整对话', '保留用户原话，表达建议分开呈现，并能够继续交流。'],
    experience: ['一段个人经历', '浓缩内容、原始表达、来源与关联词语。可修改摘要。'],
    soul: ['Me · 我', '有意义的活动、个人背景与 Soul，连接自己的成长。'],
    challenges: ['我的挑战', '找到进行中与已经结束的学习集合。'],
    'challenge-new': ['创建挑战', '明确选择内容、周期和名称，复用既有个人积累。'],
    'challenge-detail': ['继续这轮挑战', '查看内容与实际打开进度；结束本轮后仍可回顾。'],
    preferences: ['使用偏好', '母语、发音和听读速度的设计入口。'],
  };
  const learningPages = ['home', 'discover', 'result', 'word', 'talk', 'summary', 'world', 'history-list'];
  const personalPages = ['connections', 'challenges', 'challenge-new', 'challenge-detail', 'history', 'experience', 'soul', 'preferences'];
  let state = D.fresh();
  let mode = window.innerWidth <= 650 ? 'flow' : 'gallery';
  let responseTimer;
  let recognitionTimer;
  let routeGeneration = 0;
  let toastTimer;
  let modalTrigger = null;
  const systemTheme = window.matchMedia('(prefers-color-scheme: dark)');
  let themePreference = 'system';
  try { themePreference = localStorage.getItem('named.appearance') || 'system'; } catch {}
  function setTheme(value, persist = true) {
    themePreference = ['system', 'light', 'dark'].includes(value) ? value : 'system';
    const resolved = themePreference === 'system' ? (systemTheme.matches ? 'dark' : 'light') : themePreference;
    document.documentElement.dataset.theme = resolved;
    document.documentElement.style.colorScheme = resolved;
    document.querySelectorAll('[data-theme-select]').forEach(select => select.value = themePreference);
    if (persist) { try { localStorage.setItem('named.appearance', themePreference); } catch {} }
  }
  systemTheme.addEventListener('change', () => { if (themePreference === 'system') setTheme('system', false); });
  const current = (s = state) => s.entries.find(e => e.id === s.selectedId) || s.entries[0];
  const session = (s = state, e = current(s)) => e?.sessions.find(c => c.id === s.selectedSession) || e?.sessions.at(-1);
  const experience = (s = state, e = current(s)) => e?.experiences.find(x => x.id === s.selectedExperience) || e?.experiences.at(-1);
  const challenge = (s = state) => s.challenges.find(c => c.id === s.selectedChallenge) || s.challenges[0];
  const act = (text, action, cls = 'primary', attrs = '') => `<button type="button" class="${cls}" data-action="${action}" ${attrs}>${text}</button>`;
  const nav = (text, page, cls = '', attrs = '') => `<button type="button" class="${cls}" data-page="${page}" ${attrs}>${text}</button>`;
  const back = (label, page = 'home', right = '') => `<header class="topbar">${nav(icon('back', 17) + label, page, 'back')}${right}</header>`;
  const tabs = active => `<nav class="tabs" aria-label="主导航">${[['home', 'compass', '探索'], ['world', 'book', '词语'], ['history-list', 'clock', '回忆'], ['soul', 'user', '我']].map(([page, image, label]) => nav(icon(image, 21) + label, page, active === page ? 'active' : '', `aria-label="${label}" ${active === page ? 'aria-current="page"' : ''}`)).join('')}</nav>`;
  const picture = e => e?.photo ? `<img src="${esc(e.photo)}" alt="${esc(e.cn || '这次发现')}">` : A.scene(e?.art || 'tree');
  const row = (e, extra = '', attrs = '') => `<button class="memory-row" data-open-entry="${esc(e.id)}" ${attrs}><span class="mini-art">${picture(e)}</span><span class="grow"><strong>${esc(e.name)}</strong><small>${extra || esc(e.cn) + ' · ' + (e.experiences.length ? e.experiences.length + ' 段经历' : '新的发现')}</small></span>${icon('arrow', 13)}</button>`;
  const empty = (text, target = 'discover') => `<div class="empty-illustration art">${A.scene('tree')}</div><div class="empty center"><p>${text}</p>${nav('发现身边的新事物', target, 'primary wide')}</div>`;
  function mark(text) {
    return String(text).split(/(under the tree|go for a walk|watering can|water the plants|a cup of coffee|take care of|tree|mint|coffee)/gi).map((part, i) => i % 2 ? `<button class="highlight" data-term="${esc(part.toLowerCase())}">${esc(part)}</button>` : esc(part)).join('');
  }
  function message(m, index) {
    return `<article class="message ${m.role === 'user' ? 'user' : ''}" aria-label="${m.role === 'user' ? '我的原话' : 'Milo 的回应'}"><div class="bubble">${mark(m.text)}${m.native ? `<div class="native">${esc(m.native)}</div>` : ''}${m.correction ? `<details class="correction"><summary>一个更自然的说法</summary><p>${esc(m.correction)}</p><div>${esc(m.note || '')}</div></details>` : ''}<div class="message-tools"><button class="sentence-help" data-sentence-index="${index}" aria-label="查看整句释义和发音">${icon('sound', 14)} 句子帮助</button></div></div></article>`;
  }
  function onboard(s) {
    const p = s.draft;
    const top = `<div class="onboard-progress">${act(icon('back', 18), 'onboard-back', 'icon-button', 'aria-label="返回上一步"')}<span class="step-track" aria-hidden="true">${steps.map((_, i) => `<i class="${i <= s.onboardStep ? 'current' : ''}"></i>`).join('')}</span><span class="step-number">${s.onboardStep + 1} / 4</span></div>`;
    let body = '';
    if (s.onboardStep === 0) body = `<h1 class="title">什么让你<br>感到好奇？</h1><p class="sub">从喜欢的事，开始认识你的世界。</p><div class="interest-grid">${interests.map(([name, image]) => `<button class="choice ${p.interests.includes(name) ? 'selected' : ''}" data-interest="${name}" aria-pressed="${p.interests.includes(name)}"><span class="check">${p.interests.includes(name) ? icon('check', 12) : ''}</span><span class="symbol">${icon(image, 20)}</span>${name}</button>`).join('')}</div>`;
    if (s.onboardStep === 1) body = `<h1 class="title">你今年多大？</h1><p class="sub">让我们多了解你一点。</p><div class="age-entry"><input id="profile-age" type="number" inputmode="numeric" min="1" max="120" step="1" placeholder="—" value="${esc(p.age)}" aria-label="年龄"><span>岁</span></div><p id="age-error" class="form-error" role="status"></p>`;
    if (s.onboardStep === 2) body = `<h1 class="title">你的性别是？</h1><p class="sub">你也可以选择暂不透露。</p><div class="gender-choices">${[['女', '♀'], ['男', '♂'], ['不透露', '○']].map(([value, symbol]) => `<button class="choice ${p.gender === value ? 'selected' : ''}" data-gender="${value}" aria-pressed="${p.gender === value}"><span class="symbol">${symbol}</span>${value}<span class="check">${p.gender === value ? icon('check', 15) : ''}</span></button>`).join('')}</div>`;
    if (s.onboardStep === 3) body = `<h1 class="title">说说你的日常。</h1><p class="sub">一点生活背景，就能让交流更贴近你。</p><label class="form-label" for="native-language">你的母语</label><select class="field" id="native-language">${['中文', 'English', '日本語', 'Español'].map(l => `<option ${p.language === l ? 'selected' : ''}>${l}</option>`).join('')}</select><label class="form-label" for="soul-intro">生活里，有什么想聊的？</label><textarea class="field field-text" id="soul-intro" maxlength="160" placeholder="例如：喜欢散步，在阳台种了一盆薄荷。">${esc(p.bio)}</textarea><p class="onboard-note">之后的交流，会让我们慢慢熟悉。</p>`;
    return `<div class="body onboard">${top}${body}</div><div class="bottom">${act(s.onboardStep === 3 ? '开始我的英语世界' : '继续', 'onboard-next', 'primary wide')}${act(s.onboardStep === 3 ? '先开始，之后再聊' : '暂时跳过', 'onboard-skip', 'link wide')}</div>`;
  }
  function home(s) {
    const active = [...s.challenges].reverse().find(c => c.status === 'active');
    const banner = `<button class="challenge-banner" ${active ? `data-open-challenge="${active.id}"` : 'data-action="new-challenge"'}><span class="challenge-icon">${icon('flag', 18)}</span><span class="grow"><strong>${active ? esc(active.name) : '开始一轮小挑战'}</strong><small>${active ? active.days + ' 天计划 · 继续探索' : '两天、一周，按你的节奏'}</small></span>${icon('arrow', 14)}</button>`;
    return `<div class="body">
      <header class="topbar"><div class="brand">Named<span class="brand-mark">${icon('leaf', 17)}</span></div><span class="journal-label">YOUR EVERYDAY, IN ENGLISH</span></header>
      <div class="home-heading"><h1 class="editorial-title">Explore your world.</h1><p class="sub">今天，什么吸引了你？</p></div>
      <div class="explore-photo art">${A.scene('tree')}</div>
      <div class="capture-actions">${act(icon('camera', 22) + '<span>拍一张</span>', 'quick-photo', 'capture-primary')}${act(icon('mic', 22) + '<span>聊一聊</span>', 'quick-talk', 'capture-secondary')}${act(icon('edit', 21) + '<span>写点什么</span>', 'quick-text', 'capture-secondary')}</div>
      ${active ? banner : ''}
      <div class="section-head"><span>继续你的故事</span>${nav('全部回忆 →', 'history-list')}</div>
      ${s.entries.length ? s.entries.slice(0, 2).map(e => row(e)).join('') : '<p class="empty">第一个发现，会成为你自己的故事。</p>'}
      ${active ? '' : banner}
      </div>${tabs('home')}`;
  }
  function discover(s) {
    return `<div class="body">${back('新发现')}<h1 class="title">眼前有什么，<br>让你想多了解一点？</h1><div class="input-tabs"><button data-discover-mode="picture" class="${s.discoverMode === 'picture' ? 'active' : ''}">${icon('camera', 16)} 图片</button><button data-discover-mode="text" class="${s.discoverMode === 'text' ? 'active' : ''}">${icon('edit', 15)} 文字</button></div>${s.discoverMode === 'picture' ? `<button class="photo-zone" data-action="choose-photo" aria-label="选择发现的图片">${s.upload ? `<img src="${esc(s.upload)}" alt="所选图片">` : icon('camera', 34) + '<span>留下眼前的发现</span>'}</button><div class="photo-actions">${act('拍一张', 'take-photo', 'secondary')}${act('从相册选', 'choose-photo', 'secondary')}</div><input type="file" id="camera-file" accept="image/*" capture="environment" hidden><input type="file" id="image-file" accept="image/*" hidden><label class="form-label" for="discover-context">补充一点背景 <span class="label">选填</span></label>` : '<label class="form-label" for="discover-context">你遇见了什么？</label>'}<textarea class="field field-text" id="discover-context" placeholder="一个事物，或一件想表达的事。">${esc(s.discoverText)}</textarea>${s.discoveryError ? `<div class="notice" role="status">暂时没有识别成功，输入还在，可以再试一次。</div>` : ''}</div><div class="bottom">${act(s.processing ? '<span class="thinking" style="background:none;color:inherit"><i></i><i></i><i></i> 正在认识它</span>' : '一起认识它 ' + icon('arrow', 15), 'recognize', 'primary wide', s.processing ? 'disabled' : '')}</div>`;
  }
  function result(s) {
    const candidate = D.catalog[s.recognitionKey] || D.catalog.tree;
    return `<div class="body">${back('这次发现', 'discover')}<div class="result-art art">${s.upload ? `<img src="${esc(s.upload)}" alt="本次发现">` : A.scene(candidate.art)}</div><div class="recognized-label">${icon('sparkle', 14)} 从你关注的事物开始</div><h1 class="title" style="font-size:25px">你想先认识哪一部分？</h1><button class="result-choice selected" data-action="accept-result"><span class="grow"><strong>${esc(candidate.name)}</strong><small>${esc(candidate.cn)} · ${candidate.type === 'scene' ? '一个生活场景' : '眼前的一个词'}</small></span><span class="check-box selected">${icon('check', 13)}</span></button><button class="result-choice" data-action="accept-scene"><span class="grow"><strong style="font:600 15px var(--font)">聊聊整个场景</strong><small>从发生的事，找到想表达的英语</small></span>${icon('arrow', 14)}</button>${s.discoverText ? `<div class="context-box"><span class="label">你的描述</span><p>${esc(s.discoverText)}</p></div>` : ''}</div><div class="bottom">${act('认识 ' + esc(candidate.name) + ' ' + icon('arrow', 15), 'accept-result', 'primary wide')}${act('调整名称', 'adjust-result', 'link wide')}</div>`;
  }
  function word(s, e) {
    if (!e) return `<div class="body">${back('我的发现')}${empty('先认识一个真实的事物吧。')}</div>`;
    return `<div class="body">${back('这次发现', 'connections', nav(icon('world', 19), 'connections', 'icon-button', 'aria-label="查看这个词的个人世界"'))}<div class="word-art art">${picture(e)}</div><div class="word-row"><div><h1 class="word ${e.name.length > 12 ? 'long' : ''}">${esc(e.name)}</h1><div class="translation">${esc(e.cn)}${e.ipa ? ' · ' + esc(e.ipa) : ''} · ${esc(e.pos)}</div></div>${act(icon('sound', 21), 'audio', 'audio', 'aria-label="听发音"')}</div><div class="speed">${['0.75', '1', '1.25'].map(speed => `<button data-speed="${speed}" class="${s.preferences.speed === speed ? 'selected' : ''}">${speed}×${speed === '1' ? ' 正常' : ''}</button>`).join('')}</div><div class="definition">${esc(e.definition)}<div class="native">${esc(e.translation)}</div></div><div class="context-box"><span class="label">${icon('pin', 12)} ${esc(e.location || '我的发现')}</span><p>${esc(e.context)}</p></div><div class="quick-links">${act('语法与用法', 'grammar', '')}${act('一起组句', 'sentence', '')}${act('场景引申', 'related', '')}</div></div><div class="bottom">${act(icon('chat', 17) + ' 和 Milo 聊聊它', 'start-talk', 'primary wide')}</div>`;
  }
  function talk(s, e) {
    if (!e) return `<div class="body">${back('交流')}${empty('从真实发现开始一次交流。')}</div>`;
    const c = session(s, e);
    const status = { idle: '我在这里，慢慢说', listening: '正在听你说…', paused: '已暂停', unclear: '刚才没有听清', thinking: '正在想一想' }[s.voice] || '我在这里';
    return `<section class="tutor ${s.voice}"><div class="tutor-top">${nav(icon('back', 16) + ' ' + esc(e.name), 'connections', 'back')}<span>${act(icon(s.voice === 'paused' ? 'play' : 'pause', 16), 'pause', 'icon-button', 'aria-label="暂停或继续"')}${act('结束', 'finish-talk', 'back')}</span></div><div class="tutor-profile">${A.avatar()}<div class="tutor-name"><span class="label">虚拟英语伙伴</span><strong>Milo</strong><span class="status-dot"></span>${status}</div></div></section><div class="transcript">${e.experiences.length ? nav(icon('clock', 12) + ' 和上次的经历相连 ' + icon('arrow', 10), 'history', 'context-pill') : ''}${s.saveState === 'error' ? `<div class="notice" role="status">对话暂未保存，内容仍在这里。${act('重试保存', 'retry-save', '')}</div>` : ''}${(c?.messages || []).map(message).join('')}${s.pendingReply ? '<div class="thinking" role="status"><i></i><i></i><i></i></div>' : ''}${s.voice === 'paused' ? `<div class="pause-card">${icon('pause', 22)}<strong>歇一会儿也没关系。</strong>${act('继续交流', 'pause', 'secondary wide')}</div>` : ''}</div><div class="composer">${s.voice === 'listening' ? '<div class="voice-state live"><span class="wave"><i></i><i></i><i></i><i></i><i></i></span>我会等你说完</div>' : ''}${s.voice === 'unclear' ? `<div class="notice" role="status">没有听清，可以重试，也可以打字。${act('再试一次', 'voice', '')}</div>` : ''}<form id="message-form"><input id="message-input" aria-label="想说的话" placeholder="用英语或母语，说点什么…" value="${esc(s.messageDraft || '')}" ${s.pendingReply || s.voice === 'paused' ? 'disabled' : ''}><button class="send" type="submit" aria-label="发送" ${s.pendingReply || s.voice === 'paused' ? 'disabled' : ''}>${icon('send', 18)}</button>${act(icon(s.voice === 'listening' ? 'check' : 'mic', 21), 'voice', 'mic ' + (s.voice === 'listening' ? 'recording' : ''), s.pendingReply || s.voice === 'paused' ? 'disabled aria-label="语音输入"' : 'aria-label="语音输入"')}</form></div>`;
  }
  function summary(s, e) {
    const x = e?.experiences.find(item => item.id === s.lastExperience);
    return `<div class="body">${back('本次交流', 'connections')}<div class="save-icon">${icon(s.saveState === 'error' ? 'retry' : 'check', 28)}</div><h1 class="summary-title">${s.saveState === 'error' ? '这段交流，还在这里。' : x ? '又多了一段自己的故事。' : '这次，先聊到这里。'}</h1><p class="summary-sub">${s.saveState === 'error' ? '暂未保存成功，重试后继续沉淀经历。' : '原话保留，每次尝试都能再次回访。'}</p>${s.saveState === 'error' ? `<div class="notice">${act('重试保存', 'retry-save', 'secondary wide')}</div>` : x ? `<button class="exp-card" data-experience="${x.id}"><span class="label">${icon('leaf', 13)} 留下的经历</span><p>${esc(x.summary)}</p><span class="source-link">查看这段经历 ${icon('arrow', 11)}</span></button><div class="connection-row"><span class="tag">${esc(e.name)}</span>${e.savedExpressions.slice(0, 2).map(p => `<span class="tag">${esc(p)}</span>`).join('')}</div><div class="soul-update">${icon('check', 13)} 已与 Soul 和个人世界相连</div>` : '<p class="empty center">本次没有新的用户表达，<br>已有内容和经历继续保留。</p>'}${e ? nav('回看完整对话', 'history', 'source-link') : ''}</div><div class="bottom">${nav('回到我的世界', 'world', 'primary wide')}${act('再聊一会儿', 'resume-talk', 'link wide')}</div>`;
  }
  function worldItems(s) {
    const q = (s.query || '').trim().toLowerCase();
    const entries = s.entries.filter(e => (s.filter === 'all' || e.type === s.filter) && (e.name + ' ' + e.cn + ' ' + e.context).toLowerCase().includes(q));
    return entries.length ? `<div class="world-cards">${entries.map(e => `<button class="word-card" data-open-entry="${e.id}"><div class="art">${picture(e)}</div><div class="info"><h2>${esc(e.name)}</h2><small>${esc(e.cn)} · ${esc(e.location || '我的发现')}</small><div class="tiny-count">${e.experiences.length} 段经历 · ${e.sessions.length} 次交流</div></div></button>`).join('')}</div>` : '<div class="empty">没有找到相应内容。试试英文、母语名称或场景。</div>';
  }
  function world(s) {
    return `<div class="body"><header class="topbar"><span class="page-name">Words</span><span class="label">${s.entries.length} 个发现</span></header><h1 class="editorial-title">A world of your own.</h1><p class="sub">每个词，都有与你有关的故事。</p>${s.entries.length ? `<label class="search">${icon('search', 17)}<input id="world-search" aria-label="搜索词语或场景" placeholder="搜索词语、场景或一段回忆" value="${esc(s.query)}"></label><div class="filter-row" aria-label="内容类型">${[['all', '全部'], ['word', '词语'], ['scene', '场景']].map(([value, title]) => `<button data-filter="${value}" class="${s.filter === value ? 'active' : ''}">${title}</button>`).join('')}</div><div id="world-results">${worldItems(s)}</div>` : empty('每一个真实发现，<br>都能成为这个世界的一部分。')}</div>${tabs('world')}`;
  }
  function historyItems(s) {
    const query = (s.historyQuery || '').trim().toLowerCase();
    const records = s.entries.flatMap(e => e.sessions.map(c => ({ e, c, x: e.experiences.filter(x => x.sessionId === c.id).at(-1) }))).filter(({ e, c }) => (e.name + ' ' + e.cn + ' ' + e.context + ' ' + c.label).toLowerCase().includes(query)).sort((a, b) => (b.c.date || '').localeCompare(a.c.date || ''));
    if (!records.length) return '<p class="empty">还没有找到这段回忆。<br>新的交流会留在这里，随时可以回来。</p>';
    return records.map(({ e, c, x }) => {
      const date = c.date ? new Date(c.date + 'T12:00:00').toLocaleDateString('zh-CN', { month: 'long', day: 'numeric' }) : c.when;
      return `<button class="journal-card" data-session="${c.id}">
        <div class="journal-card-top"><span class="label">${esc(date)} · ${esc(e.location)}</span>${icon('arrow', 13)}</div>
        <div class="journal-card-content"><span class="mini-art">${picture(e)}</span><span class="grow"><strong>${esc(c.label)}</strong><span class="sub">${esc(x?.summary || e.context)}</span></span></div>
        <div class="journal-meta"><span>${esc(e.name)}</span><span>${c.messages.length} 条交流 · ${e.savedExpressions.length} 个关联表达</span></div>
        </button>`;
    }).join('');
  }
  function historyList(s) {
    const count = s.entries.reduce((sum, e) => sum + e.sessions.length, 0);
    return `<div class="body"><header class="topbar"><span class="page-name">History</span><span class="label">${count} 次交流</span></header><h1 class="editorial-title">Moments, remembered.</h1><p class="sub">回到那些你想说、也说过的事情。</p><label class="search">${icon('search', 17)}<input id="history-search" aria-label="搜索历史场景或话题" placeholder="找一个场景、一段经历" value="${esc(s.historyQuery || '')}"></label><div id="history-results">${historyItems(s)}</div>${!count ? nav('从一个发现开始', 'discover', 'primary wide') : ''}</div>${tabs('history-list')}`;
  }
  function sessionRow(c) {
    return `<button class="session-row" data-session="${c.id}"><span class="session-icon">${icon('chat', 18)}</span><span class="grow"><strong>${esc(c.label)}</strong><small>${esc(c.when)} · ${c.messages.length} 条交流文字</small></span>${icon('arrow', 12)}</button>`;
  }
  function connections(s, e) {
    if (!e) return `<div class="body">${back('我的世界', 'world')}${empty('从一个发现开始连接。')}</div>`;
    let panel = '';
    if (s.connectionTab === 'discovery') panel = `<div class="context-box"><span class="label">${icon('pin', 12)} ${esc(e.location)}</span><p>${esc(e.context)}</p></div><span class="label">${e.discoveries.length} 次发现 · ${e.sessions.length} 次交流</span>${e.discoveries.length > 1 ? e.discoveries.map(d => `<div class="history-summary"><span class="label">${esc(d.label)}</span>${esc(d.text)}</div>`).join('') : ''}${nav('听读与理解这个词', 'word', 'secondary wide')}${e.experiences.length ? `<div class="section-head"><span>与你有关的故事</span></div>${e.experiences.map(x => `<button class="exp-card" data-experience="${x.id}" style="margin-top:12px"><span class="label">${esc(x.when)} · ${esc(x.kind)}</span><p>${esc(x.summary)}</p><span class="source-link">回到这段经历 →</span></button>`).join('')}` : ''}`;
    if (s.connectionTab === 'conversation') panel = e.sessions.length ? e.sessions.map(sessionRow).join('') : '<p class="empty">还没有围绕它聊过。<br>从一件与你有关的小事开始吧。</p>';
    if (s.connectionTab === 'knowledge') panel = `<span class="label">相关词语与场景表达</span><div class="connection-row">${e.related.map(r => `<button class="tag" data-term="${esc(r.term)}">${esc(r.term)} · ${esc(r.cn)}</button>`).join('')}</div>${e.expressions.map(p => `<button class="session-row" data-term="${esc(p)}"><span class="grow"><strong style="font-family:var(--serif);font-size:17px">${esc(p)}</strong><small>语言延伸 · 可展开理解</small></span>${icon('arrow', 12)}</button>`).join('')}<div class="section-head"><span>我留下的表达</span></div>${e.savedExpressions.length ? `<div class="connection-row">${e.savedExpressions.map(p => `<button class="tag" data-term="${esc(p)}">${esc(p)}</button>`).join('')}</div>` : '<p class="sub">在对话中点开词句，可以把想再次使用的表达留在这里。</p>'}`;
    if (s.connectionTab === 'history') panel = `<div class="timeline">${e.discoveries.map(d => `<div class="event"><small>${esc(d.label)}</small><h3>遇见 ${esc(e.name)}</h3><p>${esc(d.text)}</p></div>`).join('')}${e.experiences.map(x => `<div class="event"><small>${esc(x.when)} · 一次新的联系</small><p>${esc(x.summary)}</p><button class="source-link" data-experience="${x.id}">回看经历 →</button></div>`).join('')}</div>`;
    return `<div class="body">${back('我的世界', 'world')}<div class="connection-hero art">${picture(e)}<span class="overlay-label">${esc(e.location)} · 真实发现</span></div><div class="connection-heading"><div><h1>${esc(e.name)}</h1><span class="sub">${esc(e.cn)} · ${e.experiences.length} 段个人经历</span></div>${act(icon('sound', 19), 'audio', 'icon-button', 'aria-label="听发音"')}</div><div class="connection-tabs" role="tablist" aria-label="这个词的关联">${[['discovery', 'Discovery'], ['conversation', 'Conversation'], ['knowledge', 'Knowledge'], ['history', 'History']].map(([id, label]) => `<button role="tab" aria-selected="${s.connectionTab === id}" data-connection-tab="${id}" class="${s.connectionTab === id ? 'active' : ''}">${label}</button>`).join('')}</div><div role="tabpanel">${panel}</div></div><div class="bottom">${act(icon('chat', 17) + (e.sessions.length ? '接着聊它的故事' : '开始它的第一段交流'), e.sessions.length ? 'resume-talk' : 'start-talk', 'primary wide')}</div>`;
  }
  function history(s, e) {
    const c = session(s, e);
    const x = e?.experiences.find(item => item.sessionId === c?.id);
    return `<div class="body">${back('完整对话', 'connections')}<span class="eyebrow">${esc(e?.cn || '我的发现')} · ${esc(c?.when || '新的交流')}</span><h1 class="title" style="margin-top:12px">${esc(c?.label || '还没有对话')}</h1>${x ? `<button class="history-summary wide" style="text-align:left" data-experience="${x.id}"><span class="label">与这段经历相连</span>${esc(x.summary)}</button>` : ''}${c ? c.messages.map(message).join('') : '<p class="empty">从这个发现开启一次交流。</p>'}</div><div class="bottom">${act('从这里继续聊 ' + icon('arrow', 15), 'resume-talk', 'primary wide')}</div>`;
  }
  function experienceView(s, e) {
    const x = experience(s, e);
    if (!x) return `<div class="body">${back('个人经历', 'connections')}<p class="empty">还没有相关经历。聊过的内容会逐渐留下来。</p></div>`;
    return `<div class="body">${back('这段经历', 'connections', act(icon('edit', 18), 'edit-experience', 'icon-button', 'aria-label="修改经历摘要"'))}<span class="eyebrow">${esc(x.when)} · ${esc(x.kind)}</span><h1 class="title" style="margin-top:18px">生活，留下了一点英语。</h1><section class="exp-card"><span class="label">经历摘要</span><p>${esc(x.summary)}</p></section><span class="label">当时的原始表达</span><div class="quote">${esc(x.quote)}</div><button class="session-row" data-session="${x.sessionId}"><span class="session-icon">${icon('chat', 17)}</span><span class="grow"><strong>回到来源对话</strong><small>原话、回应与表达建议都还在</small></span>${icon('arrow', 12)}</button><div class="section-head"><span>与你的世界相连</span></div><div class="connection-row"><button class="tag" data-open-entry="${e.id}">${esc(e.name)}</button><span class="tag">${esc(e.location)}</span>${e.savedExpressions.slice(0, 2).map(p => `<button class="tag" data-term="${esc(p)}">${esc(p)}</button>`).join('')}</div></div><div class="bottom">${act('从这段经历继续聊', 'resume-experience', 'primary wide')}</div>`;
  }
  function soul(s) {
    const experiences = s.entries.flatMap(e => e.experiences.map(x => ({ ...x, entry: e })));
    const conversations = s.entries.reduce((sum, e) => sum + e.sessions.length, 0);
    const expressions = new Set(s.entries.flatMap(e => e.savedExpressions)).size;
    return `<div class="body"><header class="topbar"><span class="page-name">Me</span>${nav(icon('settings', 20), 'preferences', 'icon-button', 'aria-label="使用偏好"')}</header><h1 class="editorial-title">Your world is growing.</h1><p class="sub">有意义的积累，都与你有关。</p><div class="growth-metrics"><div><strong>${s.entries.length}</strong><span>真实发现</span></div><div><strong>${conversations}</strong><span>个人交流</span></div><div><strong>${expressions}</strong><span>留下的表达</span></div></div><section class="profile-block"><div class="section-head"><span>My Soul · 逐渐认识你</span>${act('修改', 'edit-soul', '')}</div><div class="profile-facts">${[s.profile.age ? s.profile.age + ' 岁' : '', s.profile.gender, s.profile.language].filter(Boolean).map(value => `<span>${esc(value)}</span>`).join('')}</div>${s.profile.interests.length ? `<div class="connection-row">${s.profile.interests.map(i => `<span class="tag">${esc(i)}</span>`).join('')}</div>` : ''}<div class="soul-quote">${esc(s.profile.bio || '可以先分享一点日常，也可以在之后的对话中慢慢聊。')}</div></section><div class="section-head"><span>自己的探索节奏</span>${nav('我的挑战 →', 'challenges')}</div><section class="profile-block"><div class="section-head"><span>经历，让我们慢慢熟悉</span></div>${experiences.length ? experiences.map(x => `<button class="exp-card" data-experience="${x.id}" style="margin:12px 0"><span class="label">${esc(x.entry.name)} · 来自对话</span><p>${esc(x.summary)}</p><span class="source-link">查看来源 →</span></button>`).join('') : '<p class="empty">每次真实分享，都能留下可回访的经历。</p>'}</section></div>${tabs('soul')}`;
  }
  function challengeList(s) {
    const card = c => `<button class="challenge-list-card" data-open-challenge="${c.id}"><span class="status-badge ${c.status === 'ended' ? 'ended' : ''}">${c.status === 'active' ? '进行中' : '已结束'}</span><strong>${esc(c.name)}</strong><span class="meta"><span>${c.days} 天计划 · ${c.ids.length} 个发现</span><span>${c.visited.length} / ${c.ids.length} 已查看</span></span></button>`;
    return `<div class="body">${back('我的挑战')}<h1 class="title">按自己的节奏，<br>认识身边的世界。</h1><div class="section-head"><span>进行中</span></div>${s.challenges.filter(c => c.status === 'active').map(card).join('') || '<p class="empty">下一轮，想探索什么？</p>'}${s.challenges.some(c => c.status === 'ended') ? '<div class="section-head"><span>过去的探索</span></div>' + s.challenges.filter(c => c.status === 'ended').map(card).join('') : ''}</div><div class="bottom">${act(icon('plus', 17) + ' 开始新挑战', 'new-challenge', 'primary wide')}</div>`;
  }
  function challengeNew(s) {
    const d = s.challengeDraft;
    return `<form id="challenge-form" class="body">${back('新挑战', 'challenges')}<h1 class="title">这一轮，<br>想探索些什么？</h1><label class="form-label" for="challenge-name">给它起个名字</label><input class="field" id="challenge-name" value="${esc(d.name)}" maxlength="50" placeholder="例如：身边的小小发现" required><label class="form-label">按你的节奏安排</label><div class="duration-choices">${[[2, '2 天'], [7, '一周'], ['custom', '自定义']].map(([value, label]) => `<button type="button" data-duration="${value}" class="${value === 'custom' ? d.custom ? 'selected' : '' : !d.custom && d.days === value ? 'selected' : ''}">${label}</button>`).join('')}</div>${d.custom ? `<label class="form-label" for="challenge-days">准备学几天？</label><input class="field" type="number" min="1" max="365" id="challenge-days" value="${d.days}" required>` : ''}<div class="section-head"><span>选择你的发现</span><span class="label">已选 ${d.ids.length} 项</span></div>${s.entries.length ? s.entries.map(e => `<button type="button" class="selection-row" data-challenge-entry="${e.id}" aria-pressed="${d.ids.includes(e.id)}"><span class="mini-art">${picture(e)}</span><span class="grow"><strong>${esc(e.name)}</strong><small>${esc(e.cn)} · ${esc(e.location)}</small></span><span class="check-box ${d.ids.includes(e.id) ? 'selected' : ''}">${d.ids.includes(e.id) ? icon('check', 12) : ''}</span></button>`).join('') : '<p class="empty">先 Discover，再把真实发现加入这一轮。</p>'}<p id="challenge-error" class="form-error" role="status"></p></form><div class="bottom">${s.entries.length ? `<button class="primary wide" type="submit" form="challenge-form" ${d.ids.length ? '' : 'disabled'}>开始这轮挑战</button>` : nav('去发现新事物', 'discover', 'primary wide')}</div>`;
  }
  function challengeDetail(s) {
    const c = challenge(s);
    if (!c) return challengeList(s);
    return `<div class="body">${back('我的挑战', 'challenges')}<section class="challenge-large"><span class="status-badge ${c.status === 'ended' ? 'ended' : ''}">${c.status === 'active' ? '进行中' : '已结束 · 随时回顾'}</span><h2>${esc(c.name)}</h2><span class="sub">${c.days} 天计划 · ${c.ids.length} 个真实发现</span><div class="progress"><i style="width:${c.ids.length ? c.visited.length / c.ids.length * 100 : 0}%"></i></div><div class="meta"><span>已查看内容</span><span>${c.visited.length} / ${c.ids.length}</span></div></section><div class="section-head"><span>这一轮的发现</span></div>${c.ids.map(id => s.entries.find(e => e.id === id)).filter(Boolean).map(e => row(e, esc(e.cn) + ' · ' + (c.visited.includes(e.id) ? '已查看' : '等待探索'))).join('')}<p class="sub" style="font-size:10px;margin-top:20px">查看进度记录学习行为，不等同于已经掌握。</p></div><div class="bottom">${act(c.status === 'active' ? '继续探索' : '再看看这些发现', 'continue-challenge', 'primary wide')}${c.status === 'active' ? act('结束这一轮', 'end-challenge', 'link wide') : act('开始新的挑战', 'new-challenge', 'link wide')}</div>`;
  }
  function preferences(s) {
    const options = (id, values, selected) => `<select id="${id}">${values.map(v => `<option ${v === selected ? 'selected' : ''}>${v}</option>`).join('')}</select>`;
    return `<div class="body">${back('使用偏好', 'soul')}<h1 class="editorial-title">Make yourself at home.</h1><p class="sub">让交流，更适合你。</p><div class="section-head">外观</div><label class="settings-row" for="preference-theme">主题<select id="preference-theme" data-theme-select><option value="system">跟随系统</option><option value="light">浅色</option><option value="dark">深色</option></select></label><div class="section-head">语言与听读</div><label class="settings-row" for="preference-language">母语${options('preference-language', ['中文', 'English', '日本語', 'Español'], s.profile.language)}</label><label class="settings-row" for="preference-dialect">发音偏好${options('preference-dialect', ['英式', '美式'], s.preferences.dialect)}</label><label class="settings-row" for="preference-speed">默认播放速度${options('preference-speed', ['0.75', '1', '1.25'], s.preferences.speed)}</label><div class="section-head">个人背景</div>${act('修改 Soul ' + icon('arrow', 14), 'edit-soul', 'secondary wide')}${act('图片来源与署名', 'photo-credits', 'link wide')}</div>`;
  }
  function view(page, s) {
    const e = current(s);
    const views = { onboard, home, discover, result, word, talk, summary, world, 'history-list': historyList, connections, history, experience: experienceView, soul, challenges: challengeList, 'challenge-new': challengeNew, 'challenge-detail': challengeDetail, preferences };
    return views[page](s, e);
  }
  function phone(page, s, variant = '') {
    return `<section class="phone" data-snapshot="${page}" data-variant="${variant}" data-step="${s.onboardStep}" aria-label="${esc(pages[page][0])}"><div class="status"><span>9:41</span><span class="notch"></span><span>▂▄▆　◕ ▰</span></div><div class="screen">${view(page, s)}</div><span class="indicator"></span></section>`;
  }
  function snapshot(page, variant = '') {
    const s = D.seed(); s.page = page;
    if (page === 'onboard') s.onboardStep = Number(variant) || 0;
    if (page === 'summary') { s.lastExperience = 'e-tree'; s.lastSummarySession = 's-tree'; }
    if (page === 'challenge-new') s.challengeDraft = { name: '阳台与公园', days: 2, ids: ['tree', 'can'] };
    if (variant === 'empty') { const blank = D.fresh(); blank.page = page; return blank; }
    if (variant === 'listening') s.voice = 'listening';
    if (variant === 'retry') { s.voice = 'unclear'; s.saveState = 'error'; }
    return s;
  }
  function board(target, list) {
    document.getElementById(target).innerHTML = mode === 'gallery' ? list.map(([page, variant, title], i) => `<article><h3><span class="num">${i + 1}</span>${title || pages[page][0]}</h3>${phone(page, snapshot(page, variant), variant)}</article>`).join('') : '';
  }
  function render() {
    document.getElementById('gallery').hidden = mode !== 'gallery';
    document.getElementById('flow').hidden = mode !== 'flow';
    document.getElementById('overview-mode').classList.toggle('on', mode === 'gallery');
    document.getElementById('flow-mode').classList.toggle('on', mode === 'flow');
    document.body.classList.toggle('app-mode', mode === 'flow');
    board('onboarding-gallery', steps.map((name, i) => ['onboard', String(i), name]));
    board('core-gallery', learningPages.map(p => [p, '', pages[p][0]]));
    board('personal-gallery', personalPages.map(p => [p, '', pages[p][0]]));
    board('states-gallery', [['home', 'empty', '首次进入'], ['world', 'empty', '等待第一个发现'], ['talk', 'listening', '正在倾听'], ['talk', 'retry', '未听清与保存重试']]);
    document.getElementById('device').innerHTML = mode === 'flow' ? phone(state.page, state) : '';
    document.getElementById('flow-title').textContent = state.page === 'onboard' ? '认识你 · ' + steps[state.onboardStep] : pages[state.page][0];
    document.getElementById('flow-note').textContent = pages[state.page][1];
    document.getElementById('side-nav').innerHTML = Object.entries(pages).map(([p, data]) => `<button data-page="${p}" class="${state.page === p ? 'on' : ''}">${data[0]}</button>`).join('');
    for (const id of ['sample-discovery', 'mock-recognition-error', 'sample-message', 'mock-save-error', 'mock-unclear']) document.getElementById(id).hidden = ['sample-discovery', 'mock-recognition-error'].includes(id) ? state.page !== 'discover' : state.page !== 'talk';
    if (mode === 'flow' && state.page === 'talk') {
      const transcript = document.querySelector('#device .transcript');
      transcript.scrollTop = transcript.scrollHeight;
      document.querySelector('#device .tutor-top [data-action="pause"]')?.setAttribute('aria-label', state.pendingReply ? '打断回应' : '暂停或继续');
    }
    setTheme(themePreference, false);
  }
  function navigate(page) {
    if (!pages[page]) return;
    closeSheet(); mode = 'flow'; state.page = page;
    render(); window.scrollTo({ top: 0, behavior: 'instant' });
  }
  function resetScenario(name) {
    routeGeneration++; clearTimeout(responseTimer); clearTimeout(recognitionTimer);
    for (const e of state.entries) if (e.photo?.startsWith('blob:')) URL.revokeObjectURL(e.photo);
    if (state.upload) URL.revokeObjectURL(state.upload);
    state = name === 'new' || name === 'empty' ? D.fresh() : D.seed();
    if (name === 'active') state.page = 'challenge-detail';
    if (name === 'empty') state.page = 'world';
    navigate(state.page);
  }
  function openEntry(id, destination = 'connections') {
    const e = state.entries.find(item => item.id === id); if (!e) return;
    state.selectedId = e.id; state.selectedSession = e.sessions.at(-1)?.id || null; state.selectedExperience = e.experiences.at(-1)?.id || null; state.connectionTab = 'discovery';
    const c = challenge();
    if (c?.status === 'active' && c.ids.includes(id) && !c.visited.includes(id)) c.visited.push(id);
    navigate(destination);
  }
  function locateExperience(id) {
    for (const e of state.entries) {
      if (e.experiences.some(x => x.id === id)) { state.selectedId = e.id; state.selectedExperience = id; state.selectedSession = e.experiences.find(x => x.id === id).sessionId; navigate('experience'); return; }
    }
  }
  function openSession(id) {
    const e = state.entries.find(item => item.sessions.some(c => c.id === id));
    if (!e) return;
    state.selectedId = e.id; state.selectedSession = id;
    state.selectedExperience = e.experiences.filter(x => x.sessionId === id).at(-1)?.id || null;
    navigate('history');
  }
  function captureOnboard(root = document) {
    const age = root.querySelector('#profile-age');
    if (age) state.draft.age = age.value;
    const language = root.querySelector('#native-language'); if (language) state.draft.language = language.value;
    const bio = root.querySelector('#soul-intro'); if (bio) state.draft.bio = bio.value.trim();
  }
  function advanceOnboard(skip) {
    captureOnboard(document.getElementById('device'));
    const age = Number(state.draft.age);
    if (state.onboardStep === 1 && state.draft.age && (!Number.isInteger(age) || age < 1 || age > 120)) {
      if (skip) state.draft.age = '';
      else { document.getElementById('age-error').textContent = '请输入 1–120 之间的整数'; document.getElementById('profile-age').focus(); return; }
    }
    if (state.onboardStep < 3) { state.onboardStep++; render(); }
    else { state.profile = D.clone(state.draft); navigate(state.onboardReturn); }
  }
  function toast(text) {
    const el = document.getElementById('toast'); el.textContent = text; el.hidden = false;
    clearTimeout(toastTimer); toastTimer = setTimeout(() => el.hidden = true, 2700);
  }
  function positionSheet() {
    const frame = document.querySelector('#device .phone'); if (!frame) return;
    const box = frame.getBoundingClientRect();
    Object.assign(document.getElementById('modal').style, { left: box.x + 'px', top: box.y + 'px', width: box.width + 'px', height: box.height + 'px' });
  }
  function sheet(content) {
    const el = document.getElementById('modal');
    if (el.hidden) modalTrigger = document.activeElement;
    el.innerHTML = `<section class="sheet" role="dialog" aria-modal="true" aria-label="内容详情"><div class="sheet-handle"></div><div class="sheet-top"><span class="label">NAMED · 与这个词多一点联系</span>${act(icon('close', 18), 'close-sheet', 'icon-button', 'aria-label="关闭"')}</div>${content}</section>`;
    el.hidden = false; positionSheet(); el.querySelector('button')?.focus();
  }
  function closeSheet() {
    const el = document.getElementById('modal'); const wasOpen = !el.hidden;
    el.hidden = true; el.innerHTML = '';
    if (wasOpen && modalTrigger?.isConnected) modalTrigger.focus();
    modalTrigger = null;
  }
  const phrases = {
    'under the tree': ['Below the branches of a tree.', '在树下。under 表示在……下面。', 'I sat under the tree with my daughter.'],
    'go for a walk': ['Walk for pleasure or exercise.', '去散步。', 'We often go for a walk together.'],
    'watering can': [D.catalog.can.definition, D.catalog.can.translation, D.catalog.can.sentence],
    'water the plants': ['Give water to plants.', '给植物浇水。water 在这里作动词。', 'I water the plants in the morning.'],
    'take care of': ['Look after someone or something.', '照顾、照料。', 'I take care of the mint on my balcony.'],
    'a cup of coffee': ['One serving of coffee in a cup.', '一杯咖啡。', 'I enjoy a cup of coffee by the window.'],
    tree: [D.catalog.tree.definition, '树；可数名词。', D.catalog.tree.sentence],
    leaf: ['A flat, usually green part of a plant.', '叶子；复数为 leaves。', 'A leaf fell from the tree.'],
    branch: ['A part of a tree growing out from its trunk.', '树枝。', 'A bird is sitting on a branch.'],
    trunk: ['The main, thick stem of a tree.', '树干。', 'The tree has a thick trunk.'],
    mint: ['A plant with fresh-smelling leaves.', '薄荷。', 'I am growing mint on my balcony.'],
    coffee: [D.catalog.coffee.definition, D.catalog.coffee.translation, D.catalog.coffee.sentence],
  };
  function termSheet(term) {
    const r = current()?.related.find(item => item.term === term);
    const p = phrases[term] || ['A related word or expression in this situation.', r?.cn || '相关表达，完整解释待生成。', current()?.sentence || ''];
    const personal = state.entries.find(e => e.name.toLowerCase() === term.toLowerCase());
    sheet(`<h2>${esc(term)}</h2><p>${esc(p[0])}</p><p class="native">${esc(p[1])}</p><div class="history-summary">${esc(p[2])}</div><div class="row">${act(icon('sound', 17) + ' 听读', 'audio', 'secondary')}${act('留在我的知识', 'save-expression', 'primary', `data-expression="${esc(term)}"`)}</div>${personal ? `<button class="link wide" data-open-entry="${personal.id}">看看它与我的故事 ${icon('arrow', 12)}</button>` : ''}`);
  }
  function sentenceSheet(index) {
    const e = current(); const c = session(); const m = c?.messages[index];
    if (!m) return;
    const translations = { 'I sit under the tree with my daughter yesterday.': '我昨天和女儿坐在树下。原句的时态可以用过去式 sat 来表达。', 'I sat under the tree with my daughter.': '我和女儿坐在树下。', 'I am growing mint. I use a watering can.': '我正在种薄荷。我用洒水壶浇水。' };
    const native = m.native || translations[m.text] || '这句话的母语解释将在正式版本中生成。';
    const words = [e.name, ...e.related.map(r => r.term), ...e.expressions].filter(word => m.text.toLowerCase().includes(word.toLowerCase()));
    sheet(`<h2 class="sans">理解这句话</h2><div class="sentence-original">${esc(m.text)}</div><p class="native">${esc(native)}</p>${m.correction ? `<div class="correction"><strong>表达建议 · 原话保留</strong><p>${esc(m.correction)}</p></div>` : ''}${e.ipa ? `<p class="label">关键词发音 · ${esc(e.name)} ${esc(e.ipa)}</p>` : ''}<div class="connection-row">${words.map(word => `<button class="tag" data-term="${esc(word)}">${esc(word)}</button>`).join('')}</div><div class="row">${act(icon('sound', 17) + ' 重听整句', 'audio', 'secondary')}${act('慢一点', 'sentence-slow', 'primary')}</div>`);
  }
  function beginTalk(resume) {
    const e = current(); if (!e) { navigate('discover'); return; }
    let c = resume ? session() : null;
    if (!c) {
      c = { id: 's-' + state.nextId++, label: e.cn + '，和我的生活', when: '今天', date: new Date().toLocaleDateString('sv-SE'), saved: 0, messages: [] };
      e.sessions.push(c);
      c.messages.push({ role: 'ai', text: e.id === 'can' ? 'What are you growing on your balcony?' : e.id === 'coffee' ? 'What do you enjoy about your morning coffee?' : e.id === 'park' ? 'Tell me about a moment you noticed on your walk.' : e.type === 'scene' ? 'Tell me a little about this moment. What would you like to share?' : 'What caught your eye about this tree?', native: e.id === 'can' ? '你在阳台种了什么？' : e.id === 'coffee' ? '你喜欢晨间咖啡的什么？' : '说说这次发现，有什么吸引了你？' });
    } else {
      const x = e.experiences.find(item => item.id === state.selectedExperience && item.sessionId === c.id) || e.experiences.filter(item => item.sessionId === c.id).at(-1);
      if (x) c.messages.push({ role: 'ai', text: 'Last time, you shared: “' + x.quote + '” What would you like to add today?', native: '带着上次的经历继续，今天有什么想聊的？' });
    }
    state.selectedSession = c.id; state.voice = 'idle'; state.messageDraft = ''; navigate('talk');
  }
  function sendMessage(text) {
    const value = text.trim(); if (!value || state.pendingReply || state.voice === 'paused') return;
    const e = current(); const c = session(); if (!e || !c) return;
    c.messages.push({ role: 'user', text: value }); state.messageDraft = ''; state.voice = 'thinking'; state.pendingReply = true; render();
    const generation = routeGeneration;
    responseTimer = setTimeout(() => {
      if (generation !== routeGeneration) return;
      c.messages.push({ role: 'ai', text: e.id === 'can' ? 'That sounds lovely. How do you take care of the plants?' : e.id === 'coffee' ? 'That sounds like a comforting routine. What else do you do in the morning?' : 'Thank you for sharing that. What else did you notice around you?', native: '谢谢你分享。再聊聊与你有关的细节吧。' });
      state.pendingReply = false;
      if (state.voice !== 'paused') state.voice = 'idle';
      render();
    }, 550);
  }
  function finishTalk() {
    const e = current(); const c = session();
    if (!e || !c) { navigate('world'); return; }
    if (state.pendingReply) { toast('等这句回应结束，再留下本次经历'); return; }
    state.lastExperience = null; state.lastSummarySession = c.id;
    if (state.saveState !== 'error') {
      const messages = c.messages.slice(c.saved).filter(m => m.role === 'user');
      if (messages.length) {
        const quote = messages.map(m => m.text).join(' / ');
        const x = { id: 'e-' + state.nextId++, quote, summary: '用户分享：' + quote, sessionId: c.id, when: '今天', kind: '个人分享与学习' };
        e.experiences.push(x); state.lastExperience = x.id; state.selectedExperience = x.id;
      }
      c.saved = c.messages.length;
    }
    state.voice = 'idle'; navigate('summary');
  }
  function acceptResult(asScene = false) {
    const key = asScene ? 'park' : state.recognitionKey;
    let e = state.entries.find(item => item.id === key);
    if (!e) { e = D.entry(key); e.sessions = []; e.experiences = []; e.discoveries = []; e.savedExpressions = []; state.entries.unshift(e); }
    const context = state.discoverText.trim() || '从一张图片开始认识它。';
    e.context = context;
    e.location = /阳台/.test(context) ? '阳台' : /公园/.test(context) ? '公园' : /家里|家中|在家/.test(context) ? '家中' : '我的发现';
    if (!e.discoveries.some(d => d.text === context)) e.discoveries.push({ text: context, label: '今天发现' });
    if (state.upload) { e.photo = state.upload; state.upload = null; }
    state.selectedId = e.id; state.selectedSession = e.sessions.at(-1)?.id || null; state.selectedExperience = e.experiences.at(-1)?.id || null;
    navigate('word');
  }
  function captureChallenge() {
    const name = document.querySelector('#device #challenge-name'); if (name) state.challengeDraft.name = name.value;
    const days = document.querySelector('#device #challenge-days'); if (days) state.challengeDraft.days = Number(days.value);
  }
  function newChallenge() {
    state.challengeDraft = { name: '', days: 2, ids: [], custom: false }; navigate('challenge-new');
  }
  document.addEventListener('click', event => {
    const b = event.target.closest('button'); if (!b || b.disabled) return;
    if (b.dataset.mode) { if (state.page === 'onboard') captureOnboard(document.getElementById('device')); mode = b.dataset.mode; render(); return; }
    if (b.dataset.scenario) { resetScenario(b.dataset.scenario); return; }
    if (mode === 'gallery' && b.closest('.phone')) {
      const frame = b.closest('.phone'); state = snapshot(frame.dataset.snapshot, frame.dataset.variant); state.onboardStep = Number(frame.dataset.step);
      if (state.page === 'onboard') captureOnboard(frame);
      mode = 'flow'; render();
    }
    if (b.dataset.page) { navigate(b.dataset.page); return; }
    if (b.dataset.openEntry) { openEntry(b.dataset.openEntry); return; }
    if (b.dataset.experience) { locateExperience(b.dataset.experience); return; }
    if (b.dataset.session) { openSession(b.dataset.session); return; }
    if (b.dataset.openChallenge) { state.selectedChallenge = b.dataset.openChallenge; navigate('challenge-detail'); return; }
    if (b.dataset.connectionTab) { state.connectionTab = b.dataset.connectionTab; render(); return; }
    if (b.dataset.interest) { const value = b.dataset.interest; state.draft.interests = state.draft.interests.includes(value) ? state.draft.interests.filter(i => i !== value) : [...state.draft.interests, value]; render(); return; }
    if (b.dataset.gender) { state.draft.gender = b.dataset.gender; render(); return; }
    if (b.dataset.term) { termSheet(b.dataset.term); return; }
    if (b.dataset.sentenceIndex !== undefined) { sentenceSheet(Number(b.dataset.sentenceIndex)); return; }
    if (b.dataset.speed) { state.preferences.speed = b.dataset.speed; render(); toast('已选 ' + b.dataset.speed + '×；原型未接入播放'); return; }
    if (b.dataset.filter) { state.filter = b.dataset.filter; render(); return; }
    if (b.dataset.discoverMode) { state.discoverText = document.querySelector('#device #discover-context')?.value ?? state.discoverText; state.discoverMode = b.dataset.discoverMode; render(); return; }
    if (b.dataset.duration) { captureChallenge(); state.challengeDraft.custom = b.dataset.duration === 'custom'; if (!state.challengeDraft.custom) state.challengeDraft.days = Number(b.dataset.duration); render(); return; }
    if (b.dataset.challengeEntry) { captureChallenge(); const id = b.dataset.challengeEntry; const d = state.challengeDraft; d.ids = d.ids.includes(id) ? d.ids.filter(i => i !== id) : [...d.ids, id]; render(); return; }
    const action = b.dataset.action; if (!action) return;
    if (action === 'quick-photo') { state.discoverMode = 'picture'; navigate('discover'); document.getElementById('camera-file')?.click(); return; }
    if (action === 'quick-text') { state.discoverMode = 'text'; navigate('discover'); document.getElementById('discover-context')?.focus(); return; }
    if (action === 'quick-talk') { sheet(`<h2 class="sans">有什么想分享？</h2><p class="native">一个发现、一件小事，或此刻的想法。</p><label class="form-label" for="talk-topic">从这里开始</label><textarea id="talk-topic" class="field field-text" placeholder="今天在生活里，什么吸引了你？"></textarea>${act('开始聊聊', 'start-topic-talk', 'primary wide')}`); return; }
    if (action === 'start-topic-talk') {
      const text = document.getElementById('talk-topic')?.value.trim();
      if (!text) { document.getElementById('talk-topic')?.focus(); return; }
      const id = 'moment-' + state.nextId++;
      const e = { ...D.entry('park'), id, name: 'a moment from my day', cn: text.slice(0, 18), art: 'moment', context: text, location: '我的生活', definition: 'Find the words for a moment that matters to you.', translation: '用英语表达这段属于你的生活。', grammar: '可以从 I noticed…、I felt… 或 Today… 开始，描述自己真正想说的事情。', sentence: 'Today, something caught my attention.', sentenceCn: '今天，有件事吸引了我。', discoveries: [{ text, label: '今天分享' }], sessions: [], experiences: [], related: [], expressions: [], savedExpressions: [] };
      state.entries.unshift(e); state.selectedId = id; state.selectedSession = null; state.selectedExperience = null; beginTalk(false); return;
    }
    if (action === 'onboard-next' || action === 'onboard-skip') { advanceOnboard(action === 'onboard-skip'); return; }
    if (action === 'onboard-back') { captureOnboard(document.getElementById('device')); if (state.onboardStep) { state.onboardStep--; render(); } else navigate(state.onboardReturn); return; }
    if (action === 'edit-soul') { state.draft = D.clone(state.profile); state.onboardStep = 0; state.onboardReturn = 'soul'; navigate('onboard'); return; }
    if (action === 'take-photo' || action === 'choose-photo') { document.querySelector(action === 'take-photo' ? '#device #camera-file' : '#device #image-file')?.click(); return; }
    if (action === 'sample-tree') { state.recognitionKey = 'tree'; state.discoverText = '今天在公园里遇见的一棵树。'; navigate('result'); return; }
    if (action === 'mock-recognition-error') { clearTimeout(recognitionTimer); state.processing = false; state.discoveryError = true; render(); return; }
    if (action === 'recognize') {
      state.discoverText = document.querySelector('#device #discover-context')?.value.trim() ?? state.discoverText;
      if (!state.upload && !state.discoverText) { toast('先选一张图片，或写下想表达的内容'); return; }
      state.processing = true; state.discoveryError = false; render();
      const generation = routeGeneration;
      recognitionTimer = setTimeout(() => { if (generation !== routeGeneration) return; state.processing = false; state.recognitionKey = /咖啡|coffee|杯/i.test(state.discoverText) ? 'coffee' : /壶|薄荷|mint|浇水|watering/i.test(state.discoverText) ? 'can' : 'tree'; navigate('result'); }, 650); return;
    }
    if (action === 'accept-result' || action === 'accept-scene') { acceptResult(action === 'accept-scene'); return; }
    if (action === 'adjust-result') { sheet(`<h2 class="sans">你关注的是哪一个？</h2><p class="native">原型仅内置这些示例，实际产品由 AI 结合输入识别。</p>${Object.values(D.catalog).map(e => `<button class="result-choice" data-recognition-key="${e.id}"><span class="grow"><strong>${esc(e.name)}</strong><small>${esc(e.cn)}</small></span>${icon('arrow', 13)}</button>`).join('')}`); return; }
    if (action === 'start-talk' || action === 'resume-talk') { beginTalk(action === 'resume-talk'); return; }
    if (action === 'resume-experience') { const x = experience(); if (x) state.selectedSession = x.sessionId; beginTalk(true); return; }
    if (action === 'sample-utterance') { sendMessage(current()?.id === 'can' ? 'I am growing mint on my balcony.' : current()?.id === 'coffee' ? 'I enjoy a cup of coffee by the window.' : 'I sat under the tree with my daughter.'); return; }
    if (action === 'finish-talk') { finishTalk(); return; }
    if (action === 'voice') { state.voice = state.voice === 'listening' ? 'unclear' : 'listening'; render(); return; }
    if (action === 'pause') {
      if (state.pendingReply) { clearTimeout(responseTimer); state.pendingReply = false; state.voice = 'idle'; }
      else state.voice = state.voice === 'paused' ? 'idle' : 'paused';
      render(); return;
    }
    if (action === 'mock-unclear') { state.voice = 'unclear'; render(); return; }
    if (action === 'mock-save-error') { state.saveState = 'error'; render(); return; }
    if (action === 'retry-save') { state.saveState = 'saved'; if (state.page === 'summary') finishTalk(); else { render(); toast('演示：已重新保存，交流内容保留'); } return; }
    if (action === 'audio') { toast('听读入口演示 · ' + state.preferences.dialect + ' · ' + state.preferences.speed + '×'); return; }
    if (action === 'sentence-slow') { state.preferences.speed = '0.75'; toast('慢速整句播放入口 · 0.75×'); return; }
    if (action === 'photo-credits') { sheet('<h2 class="sans">图片来源</h2><p>林间、咖啡与虚拟伙伴示例肖像来自 Unsplash，依其图片许可使用。</p><p>洒水壶照片：Diego Delso，CC BY-SA 3.0。图片已缩放，展示框内按比例裁切。</p><p><a href="assets/README.md">完整来源与许可链接</a></p>'); return; }
    if (action === 'close-sheet') { closeSheet(); return; }
    if (action === 'save-expression') { const e = current(); if (e && !e.savedExpressions.includes(b.dataset.expression)) e.savedExpressions.push(b.dataset.expression); closeSheet(); render(); toast('已与这个词的知识相连'); return; }
    if (action === 'grammar') { const e = current(); if (e) sheet(`<h2 class="sans">语法与用法</h2><p>${esc(e.grammar)}</p><div class="history-summary">${esc(e.sentence)}<div class="native">${esc(e.sentenceCn)}</div></div>${act(icon('sound', 17) + ' 听例句', 'audio', 'secondary wide')}`); return; }
    if (action === 'sentence') { const e = current(); if (e) sheet(`<h2 class="sans">把它放进自己的句子。</h2><div class="history-summary">${esc(e.sentence)}<div class="native">${esc(e.sentenceCn)}</div></div><p class="native">可以聊聊你在哪里遇见它，或与它发生了什么。</p>${act('去对话里试一试', 'start-talk', 'primary wide')}`); return; }
    if (action === 'related') { state.connectionTab = 'knowledge'; navigate('connections'); return; }
    if (action === 'edit-experience') { const x = experience(); if (x) sheet(`<h2 class="sans">调整这段经历</h2><p class="native">修改摘要，原始对话仍会保留。</p><form id="experience-form"><label class="form-label" for="experience-summary">经历摘要</label><textarea id="experience-summary" class="field field-text" required maxlength="600">${esc(x.summary)}</textarea><button type="submit" class="primary wide" style="margin-top:20px">保存修改</button></form>`); return; }
    if (action === 'new-challenge') { newChallenge(); return; }
    if (action === 'continue-challenge') { const c = challenge(); const id = c?.ids.find(value => !c.visited.includes(value)) || c?.ids[0]; if (id) openEntry(id, 'word'); return; }
    if (action === 'end-challenge') { const c = challenge(); if (c) c.status = 'ended'; render(); toast('这一轮已结束，内容和故事继续保留'); return; }
  });
  // Recognition options live in a sheet and keep the user's original input.
  document.addEventListener('click', event => {
    const b = event.target.closest('[data-recognition-key]'); if (!b) return;
    state.recognitionKey = b.dataset.recognitionKey; closeSheet(); render();
  });
  document.addEventListener('submit', event => {
    if (event.target.id === 'message-form') { event.preventDefault(); sendMessage(event.target.querySelector('#message-input').value); }
    if (event.target.id === 'experience-form') { event.preventDefault(); const value = event.target.querySelector('#experience-summary').value.trim(); if (!value) return; const x = experience(); if (x) x.summary = value; closeSheet(); render(); toast('已更新摘要，原始交流保持不变'); }
    if (event.target.id === 'challenge-form') {
      event.preventDefault(); captureChallenge(); const d = state.challengeDraft;
      if (!d.name.trim() || !Number.isInteger(d.days) || d.days < 1 || d.days > 365 || !d.ids.length) { document.getElementById('challenge-error').textContent = '请填写名称、有效天数，并选择至少一个发现。'; return; }
      const c = { id: 'c-' + state.nextId++, name: d.name.trim(), days: d.days, ids: [...d.ids], visited: [], status: 'active' };
      state.challenges.push(c); state.selectedChallenge = c.id; navigate('challenge-detail');
    }
  });
  document.addEventListener('input', event => {
    if (event.target.id === 'message-input') state.messageDraft = event.target.value;
    if (event.target.id === 'discover-context') state.discoverText = event.target.value;
    if (event.target.id === 'challenge-name') state.challengeDraft.name = event.target.value;
    if (event.target.id === 'challenge-days') state.challengeDraft.days = Number(event.target.value);
    if (event.target.id === 'world-search') { state.query = event.target.value; document.getElementById('world-results').innerHTML = worldItems(state); }
    if (event.target.id === 'history-search') { state.historyQuery = event.target.value; document.getElementById('history-results').innerHTML = historyItems(state); }
  });
  document.addEventListener('change', event => {
    const id = event.target.id;
    if (event.target.matches('[data-theme-select]')) { setTheme(event.target.value); return; }
    if (id === 'preference-language') state.profile.language = event.target.value;
    if (id === 'preference-dialect') state.preferences.dialect = event.target.value;
    if (id === 'preference-speed') state.preferences.speed = event.target.value;
    if (!['camera-file', 'image-file'].includes(id)) return;
    const file = event.target.files?.[0]; if (!file) return;
    if (!file.type.startsWith('image/')) { toast('请选择图片文件'); return; }
    if (state.upload) URL.revokeObjectURL(state.upload);
    state.upload = URL.createObjectURL(file); state.discoverText = document.querySelector('#device #discover-context')?.value ?? state.discoverText; render();
  });
  document.getElementById('modal').addEventListener('click', event => { if (event.target.id === 'modal') closeSheet(); });
  document.addEventListener('keydown', event => {
    const modal = document.getElementById('modal'); if (modal.hidden) return;
    if (event.key === 'Escape') { closeSheet(); return; }
    if (event.key === 'Tab') {
      const focusable = [...modal.querySelectorAll('button:not([disabled]), input, textarea, select, a[href]')];
      const first = focusable[0]; const last = focusable.at(-1);
      if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus(); }
      if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
    }
  });
  function route() {
    const hash = location.hash.slice(1);
    if (hash === 'overview') { mode = 'gallery'; render(); return; }
    routeGeneration++; clearTimeout(responseTimer); clearTimeout(recognitionTimer);
    if (['new', 'returning', 'active', 'empty'].includes(hash)) { resetScenario(hash); return; }
    const onboarding = hash.match(/^onboard-([1-4])$/);
    if (onboarding) { state = D.seed(); state.onboardStep = Number(onboarding[1]) - 1; navigate('onboard'); return; }
    if (hash === 'listening' || hash === 'retry') { state = snapshot('talk', hash); navigate('talk'); return; }
    if (pages[hash]) { state = snapshot(hash); navigate(hash); return; }
    if (mode === 'flow') state = D.seed();
    render();
  }
  window.addEventListener('hashchange', route);
  window.addEventListener('resize', () => { document.body.classList.toggle('app-mode', mode === 'flow'); if (!document.getElementById('modal').hidden) positionSheet(); });
  window.addEventListener('scroll', () => { if (!document.getElementById('modal').hidden) positionSheet(); });
  setTheme(themePreference, false);
  route();
})();
