window.NamedData = (() => {
  const profile = () => ({ interests: [], age: '', gender: '', language: '中文', bio: '' });
  const catalog = {
    tree: { id: 'tree', name: 'tree', cn: '树', type: 'word', art: 'tree', ipa: '/triː/', pos: 'noun', definition: 'A tall plant with a trunk, branches, and leaves.', translation: '一种有树干、树枝和叶子的高大植物。', context: '在公园里散步，注意到一棵能乘凉的大树。', location: '公园', grammar: 'tree 是可数名词。单数可用 a tree，复数为 trees。', sentence: 'We sat under the tree.', sentenceCn: '我们坐在树下。', related: [{ term: 'leaf', cn: '叶子' }, { term: 'branch', cn: '树枝' }, { term: 'trunk', cn: '树干' }], expressions: ['under the tree', 'go for a walk'] },
    can: { id: 'can', name: 'watering can', cn: '洒水壶', type: 'word', art: 'can', ipa: '/ˈwɔːtərɪŋ kæn/', pos: 'noun', definition: 'A container with a handle and a spout, used for watering plants.', translation: '带有把手和壶嘴、用来给植物浇水的容器。', context: '在阳台照顾新种的薄荷，想知道洒水壶怎么说。', location: '阳台', grammar: 'watering can 是可数名词短语，复数为 watering cans。water 也可以作动词，表示浇水。', sentence: 'I use a watering can to water the mint.', sentenceCn: '我用洒水壶给薄荷浇水。', related: [{ term: 'mint', cn: '薄荷' }, { term: 'soil', cn: '土壤' }, { term: 'plant', cn: '植物' }], expressions: ['water the plants', 'take care of'] },
    coffee: { id: 'coffee', name: 'coffee', cn: '咖啡', type: 'word', art: 'coffee', ipa: '/ˈkɒfi/', pos: 'noun', definition: 'A drink made from the roasted seeds of the coffee plant.', translation: '由烘焙后的咖啡豆制成的饮品。', context: '早上在窗边喝咖啡，聊聊自己的日常习惯。', location: '家中', grammar: 'coffee 表示饮品时通常不可数。一杯咖啡可以说 a cup of coffee。', sentence: 'I like a cup of coffee in the morning.', sentenceCn: '我喜欢早上喝一杯咖啡。', related: [{ term: 'mug', cn: '马克杯' }, { term: 'aroma', cn: '香气' }, { term: 'morning', cn: '早晨' }], expressions: ['a cup of coffee', 'morning routine'] },
    park: { id: 'park', name: 'a walk in the park', cn: '公园散步', type: 'scene', art: 'tree', ipa: '', pos: 'situation', definition: 'Talk about a walk, the things you notice, and the people you share it with.', translation: '聊聊散步时遇见的事物，以及和谁一起度过这段时光。', context: '周末和女儿在公园散步，想描述一路上的小发现。', location: '公园', grammar: 'go for a walk 表示去散步；in the park 表示在公园里。', sentence: 'We went for a walk in the park.', sentenceCn: '我们去公园散步了。', related: [{ term: 'tree', cn: '树' }, { term: 'path', cn: '小路' }, { term: 'shade', cn: '树荫' }], expressions: ['go for a walk', 'under the tree'] },
  };
  const clone = value => JSON.parse(JSON.stringify(value));
  function entry(key) { return { ...clone(catalog[key]), photo: null, discoveries: [{ text: catalog[key].context, label: '上次发现' }], sessions: [], experiences: [], savedExpressions: [] }; }
  function fresh() {
    return { page: 'onboard', onboardStep: 0, profile: profile(), draft: profile(), onboardReturn: 'home', entries: [], selectedId: null, selectedSession: null, selectedExperience: null, lastExperience: null, lastSummarySession: null, challenges: [], selectedChallenge: null, challengeDraft: { name: '', days: 2, ids: [] }, discoverMode: 'picture', discoverText: '', upload: null, recognitionKey: 'tree', voice: 'idle', saveState: 'saved', processing: false, filter: 'all', query: '', connectionTab: 'discovery', preferences: { speed: '1', dialect: '英式' }, scenario: 'new', nextId: 10 };
  }
  function seed() {
    const s = fresh();
    s.page = 'home'; s.scenario = 'returning';
    s.profile = { interests: ['自然', '旅行'], age: '33', gender: '男', language: '中文', bio: '喜欢和女儿一起散步，在阳台种了一盆薄荷。' };
    s.draft = clone(s.profile);
    s.entries = ['tree', 'can', 'coffee', 'park'].map(entry);
    s.entries[0].sessions.push({ id: 's-tree', label: '树下的小小休息', when: '上次', date: '2026-11-02', saved: 3, messages: [
      { role: 'ai', text: 'What caught your eye about this tree?', native: '这棵树有什么吸引了你？' },
      { role: 'user', text: 'I sit under the tree with my daughter yesterday.', correction: 'I sat under the tree with my daughter yesterday.', note: '讲昨天发生的事，用过去式 sat。' },
      { role: 'ai', text: 'That sounds like a lovely moment. Do you often go for a walk together?', native: '听起来是很美好的片刻。你们经常一起散步吗？' },
    ] });
    s.entries[0].experiences.push({ id: 'e-tree', summary: '和女儿一起在树下休息，练习描述昨天的这段经历。', quote: 'I sit under the tree with my daughter yesterday.', sessionId: 's-tree', when: '上次', kind: '个人分享与表达练习' });
    s.entries[0].savedExpressions = ['under the tree'];
    s.entries[1].sessions.push({ id: 's-can', label: '阳台上的薄荷', when: '上次', date: '2026-11-01', saved: 3, messages: [
      { role: 'ai', text: 'What are you growing on your balcony?', native: '你在阳台上种了什么？' },
      { role: 'user', text: 'I am growing mint. I use a watering can.' },
      { role: 'ai', text: 'Mint smells lovely. Do you use it in tea or cooking?', native: '薄荷的味道很好闻。你用它泡茶还是做菜？' },
    ] });
    s.entries[1].experiences.push({ id: 'e-can', summary: '在阳台种薄荷，并用洒水壶照顾它。', quote: 'I am growing mint. I use a watering can.', sessionId: 's-can', when: '上次', kind: '个人分享' });
    s.selectedId = 'tree'; s.selectedSession = 's-tree'; s.selectedExperience = 'e-tree';
    s.challenges = [
      { id: 'c-park', name: '身边的小小发现', days: 2, ids: ['tree', 'can'], visited: ['tree'], status: 'active' },
      { id: 'c-coffee', name: '我的晨间日常', days: 3, ids: ['coffee'], visited: ['coffee'], status: 'ended' },
    ];
    s.selectedChallenge = 'c-park';
    return s;
  }
  return { catalog, clone, entry, fresh, seed };
})();
