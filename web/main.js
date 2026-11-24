(function () {
  "use strict";

  const COPY = {
    en: {
      meta: {
        title: "Named — One word, one story",
        description: "Named turns what you notice into a word you keep: a timeline, a notebook, practice, and a daily story made from your own words.",
      },
      skip: "Skip to content",
      nav: {
        home: "Named — home",
        primary: "Primary",
        language: "Language",
        idea: "The idea",
        loop: "The loop",
        story: "A story",
        library: "Your library",
        early: "Get early access",
        menuOpen: "Open menu",
        menuClose: "Close menu",
      },
      hero: {
        eyebrow: "Your everyday, in English",
        title: "One word,<br><em>one story.</em>",
        lede: "Name what you notice. Keep the word. Meet it again in practice, and in a story made from your own days.",
        prompt: "What did you see today?",
        placeholder: "A tree, a cup of coffee, my daughter…",
        submit: "Try this word",
        note: "No sign-up. Just one word.",
        see: "See the loop",
        early: "Get early access",
        metaOne: "iOS + Android · Coming soon",
        metaTwo: "Private by default · No streaks",
        caption: "A real moment, kept.",
        talk: "Talk about it",
        chipsAria: "Try a word",
        cardAria: "Example word",
      },
      chip: {
        tree: "A tree",
        coffee: "Coffee",
        wateringcan: "A watering can",
        daughter: "My daughter",
      },
      idea: {
        eyebrow: "01 — The idea",
        title: "Most tools teach words.<br><em>Named starts from your life.</em>",
        p1: "A word becomes yours when it is tied to something you saw, said, or felt. Named begins with a question: what caught your eye today?",
        p2: "From there, the word is not a flashcard. It becomes a card in your timeline, a line in your notebook, a step in practice, and a sentence in a story made from your own words.",
        quote: "One thread over and under: the new word tied to what you already know.",
        tile1: "tree · the park",
        tile2: "watering can · the balcony",
        tile3: "coffee · morning",
      },
      film: {
        eyebrow: "02 — The loop",
        title: "From a word<br><em>to a story.</em>",
        lede: "Five quiet moves. No units to finish, no streak to protect. The same word comes back in a new context.",
        preview: "Conversation preview",
        dialogue: {
          caption: "One word, passed back and forth.",
          you: "You",
          named: "Named",
          moreNatural: "More natural English",
          kept: "Kept in your notebook",
          keepUser: "Keep this one.",
          oneReturn: "One quiet return",
          readIt: "Read it to me.",
          fromWords: "From your words",
          listen: "Listen",
          listenStory: "Listen to the story",
          fullStory: "Read the full story",
          useThis: "Use this",
          used: "Used",
          noScore: "Yes. No score, no streak.",
          playWord: "Play the pronunciation",
        },
        step1: { title: "See it", desc: "One feed for what you noticed, talked about, and read.", tag: "Timeline" },
        step2: { title: "Say it", desc: "Milo replies, and quietly offers a more accurate English.", tag: "Talk" },
        step3: { title: "Keep it", desc: "The word goes into your notebook, with its sounds, meaning, and chunk.", tag: "Words" },
        step4: { title: "Practice it", desc: "A five-step return: understand, recall, use. No score.", tag: "Practice" },
        step5: { title: "Meet it again", desc: "A short daily story brings the word back in a new context.", tag: "Daily" },
      },
      story: {
        eyebrow: "03 — A story",
        title: "A story made<br><em>from your words.</em>",
        lede: "Every day, Named writes a short story using the words you kept. Read it, listen to it, and meet your words in a new light.",
        quote: "Not a quiz. Not a streak. Just a story.",
        note: "Tap the underlined word to hear it and see how it is used.",
        date: "Mon, Nov 23",
        storyTitle: "The Sound Under the Floor",
        listen: "Listen",
        listenAria: "Listen to today's story",
        from: "Made with your words",
      },
      library: {
        eyebrow: "04 — Your library",
        title: "Everything stays<br><em>in one place.</em>",
        lede: "Your words, your talks, your readings, and the moments worth returning to.",
        row1: { title: "Challenges", desc: "A plan for what to revisit." },
        row2: { title: "Daily listen/read", desc: "A short story made from your words." },
        row3: { title: "Words", desc: "The notebook you are building." },
        row4: { title: "History", desc: "Experiences worth looking back on." },
        caption: "Me — your profile, your library, your words.",
      },
      principles: {
        eyebrow: "05 — Why it feels different",
        title: "Calm by design.",
        one: { title: "Life first", desc: "A real photo or one honest sentence leads. Chrome stays quiet." },
        two: { title: "No streaks", desc: "No scores, no pressure, no leaderboard. Returning is enough." },
        three: { title: "Yours to keep", desc: "Your words and moments are private. Soul is yours to shape." },
      },
      cta: {
        eyebrow: "Begin",
        title: "Start with<br><em>one word.</em>",
        lede: "Named is coming to iOS and Android. Leave a note and we will write when it is ready.",
        placeholder: "you@example.com",
        emailLabel: "Email address",
        button: "Join the waitlist",
        note: "One email when it is ready. No noise.",
        success: "You are on the list. We will write when Named is ready.",
      },
      footer: {
        tagline: "One word, one story.",
        support: "Start with one word, and build your own English world.",
        product: "Product",
        more: "More",
        github: "GitHub",
        note: "© 2026 Named",
        top: "Back to top",
      },
      toast: {
        invalid: "Please enter a valid email address.",
        ready: "You are on the list. Thank you.",
        try: "Try a tree, coffee, a watering can, or your daughter.",
        audio: "Audio is not available in this browser.",
        useThis: "That sentence is yours now.",
      },
    },
    zh: {
      meta: {
        title: "Named — 一个词，一个故事",
        description: "Named 把你看见的东西，变成一个留下的词：一条时间线、一本笔记本、练习，以及用你自己的词写成的每日故事。",
      },
      skip: "跳到内容",
      nav: {
        home: "Named — 首页",
        primary: "主导航",
        language: "语言",
        idea: "理念",
        loop: "产品",
        story: "每日故事",
        library: "你的世界",
        early: "预约体验",
        menuOpen: "打开菜单",
        menuClose: "关闭菜单",
      },
      hero: {
        eyebrow: "你的日常，用英语说出来",
        title: "一个词，<br><em>一个故事。</em>",
        lede: "命名你看见的东西，留下这个词；在练习里再遇见它，也在用你自己的日子写成的故事里再遇见它。",
        prompt: "今天，你看见了什么？",
        placeholder: "一棵树、一杯咖啡、我的女儿……",
        submit: "试试这个词",
        note: "不用注册，先用一个词试试。",
        see: "看看这个词如何走完一圈",
        early: "预约体验",
        metaOne: "iOS + Android · 即将到来",
        metaTwo: "默认私密 · 不打卡",
        caption: "一个真实的瞬间，被留下。",
        talk: "聊聊它",
        chipsAria: "试试一个词",
        cardAria: "示例单词",
      },
      chip: {
        tree: "一棵树",
        coffee: "一杯咖啡",
        wateringcan: "一个洒水壶",
        daughter: "我的女儿",
      },
      idea: {
        eyebrow: "01 — 理念",
        title: "大多数工具教你单词。<br><em>Named 从你的生活开始。</em>",
        p1: "当一个词和你看见、说出、感受到的东西连在一起，它才真正属于你。Named 从一个问题开始：今天，什么吸引了你的注意？",
        p2: "从那里开始，这个词不是一张闪卡。它会变成时间线上的一张卡、笔记本里的一行、练习里的一步，以及一个用你自己的话写成的故事里的一句。",
        quote: "一根线，一上一下：把刚命名的词，和已经知道的经历系在一起。",
        tile1: "树 · 公园",
        tile2: "洒水壶 · 阳台",
        tile3: "咖啡 · 清晨",
      },
      film: {
        eyebrow: "02 — 一圈",
        title: "从一个词，<br><em>到一个故事。</em>",
        lede: "五个安静的动作。没有要完成的单元，没有要保护的连胜。同一个词，会在新的语境里回来。",
        preview: "对话预览",
        dialogue: {
          caption: "一个词，在你们之间来回。",
          you: "你",
          named: "Named",
          moreNatural: "更自然的英文",
          kept: "已放进你的笔记本",
          keepUser: "留下这个词。",
          oneReturn: "一次安静的回来",
          readIt: "读给我听。",
          fromWords: "用你的词写成",
          listen: "朗读",
          listenStory: "朗读故事",
          fullStory: "读完整故事",
          useThis: "用这句",
          used: "已用",
          noScore: "对。没有分数，也不打卡。",
          playWord: "播放发音",
        },
        step1: { title: "看见", desc: "一条时间线，收好你看见、聊过、读过的内容。", tag: "时间线" },
        step2: { title: "说出", desc: "Milo 会自然回复，也会悄悄给你一个更准确的英文。", tag: "聊聊" },
        step3: { title: "留下", desc: "词进入你的笔记本，带着发音、意思和一个能用的搭配。", tag: "词语" },
        step4: { title: "练习", desc: "五步回来：理解、回忆、使用。没有分数。", tag: "练习" },
        step5: { title: "再遇见", desc: "一段每日短故事，让这个词在新的语境里回来。", tag: "每日" },
      },
      story: {
        eyebrow: "03 — 每日故事",
        title: "用你的词，<br><em>写一个故事。</em>",
        lede: "每天，Named 用你留下的词写一段短故事。读它、听它，让你的词在新的光里出现。",
        quote: "不是测验，也不是打卡。只是一个故事。",
        note: "点一下带下划线的词，听发音、看用法。",
        date: "11 月 23 日，周一",
        storyTitle: "地板下的声音",
        listen: "朗读",
        listenAria: "朗读今天的故事",
        from: "用你的词写成",
      },
      library: {
        eyebrow: "04 — 你的世界",
        title: "所有东西，<br><em>都在一个地方。</em>",
        lede: "你的词、你的对话、你的阅读，还有那些值得回看的时刻。",
        row1: { title: "挑战", desc: "想重新看的内容，做成一个计划。" },
        row2: { title: "每日听读", desc: "用你的词写成的短故事。" },
        row3: { title: "词语", desc: "你正在建立的笔记本。" },
        row4: { title: "回忆", desc: "值得回看的生活与学习经历。" },
        caption: "我 — 你的资料、你的世界、你的词。",
      },
      principles: {
        eyebrow: "05 — 为什么不一样",
        title: "安静，是设计出来的。",
        one: { title: "生活优先", desc: "一张真实的照片，或一句诚实的话，先出现在画面里。界面保持安静。" },
        two: { title: "不打卡", desc: "没有分数、没有压力、没有排行榜。回来就足够了。" },
        three: { title: "只属于你", desc: "你的词和时刻是私密的。Soul 由你自己塑造。" },
      },
      cta: {
        eyebrow: "开始",
        title: "从一个词<br><em>开始。</em>",
        lede: "Named 即将来到 iOS 和 Android。留下邮箱，准备好时我们会写信告诉你。",
        placeholder: "you@example.com",
        emailLabel: "邮箱地址",
        button: "加入等待名单",
        note: "准备好时只写一封邮件，不打扰。",
        success: "你已在名单里。Named 准备好时，我们会写信告诉你。",
      },
      footer: {
        tagline: "一个词，一个故事。",
        support: "从一个词开始，建立自己的英语世界。",
        product: "产品",
        more: "更多",
        github: "GitHub",
        note: "© 2026 Named",
        top: "回到顶部",
      },
      toast: {
        invalid: "请输入有效的邮箱地址。",
        ready: "你已在名单里，谢谢。",
        try: "试试一棵树、一杯咖啡、一个洒水壶，或你的女儿。",
        audio: "这个浏览器暂时不能播放音频。",
        useThis: "这句话现在属于你了。",
      },
    },
  };

  const WORDS = {
    tree: {
      word: "tree",
      ipa: "/triː/",
      pos: "noun",
      zh: "树",
      def: "A tall plant with a trunk, branches, and leaves.",
      defZh: "一种有树干、树枝和叶子的高大植物。",
      chunk: "under the tree",
      chunkZh: "在树下",
      chunks: [{ t: "leaf", zh: "叶子" }, { t: "branch", zh: "树枝" }, { t: "trunk", zh: "树干" }],
      from: { en: "From your walk in the park.", zh: "来自公园里的散步。" },
      see: "I stopped under a tree this morning.",
      practice: { cue: "I sat ___ the tree with my daughter.", answer: "under." },
      alt: "Sunlight falling through tall trees in a quiet forest",
      photo: "assets/forest.jpg",
      chat: {
        question: "What did you notice about the tree?",
        user: "I sit under tree with my daughter yesterday.",
        corrected: "I sat under the tree with my daughter yesterday.",
        correctedHtml: "I <span class=\"u\">sat</span> under <span class=\"u\">the</span> tree with my daughter yesterday.",
        note: "sit → sat; add “the” before tree.",
        reply: "That sounds like a lovely moment. Was the tree tall?",
      },
      example: "I sat under the tree with my daughter.",
      story: {
        title: "The Tree by the Path",
        html: "At seven in the morning, the path was still cool under the <span class=\"u\">tree</span>. She stood there with her daughter and listened to the leaves. A small wind moved through the branches, and the whole morning felt close.",
        loopHtml: "At seven in the morning, the path was still cool under the <span class=\"u\">tree</span>. She stood there with her daughter and listened to the leaves.",
        words: "tree · path · leaves",
      },
    },
    coffee: {
      word: "coffee",
      ipa: "/ˈkɒfi/",
      pos: "noun",
      zh: "咖啡",
      def: "A hot drink made from roasted beans.",
      defZh: "用烘焙过的咖啡豆冲成的热饮。",
      chunk: "a quiet morning",
      chunkZh: "安静的早晨",
      chunks: [{ t: "cup", zh: "杯子" }, { t: "bean", zh: "咖啡豆" }, { t: "morning", zh: "早晨" }],
      from: { en: "From your first cup today.", zh: "来自今天的第一杯。" },
      see: "I made coffee before the sun came up.",
      practice: { cue: "I have ___ coffee every morning.", answer: "a." },
      alt: "A cup of coffee held in warm morning light",
      photo: "assets/coffee.jpg",
      chat: {
        question: "What do you notice about that first cup?",
        user: "I drink a coffee every morning.",
        corrected: "I have a coffee every morning.",
        correctedHtml: "I <span class=\"u\">have</span> a coffee every morning.",
        note: "“Have a coffee” is the usual phrase.",
        reply: "A quiet morning ritual. What do you notice about that first cup?",
      },
      example: "I have a coffee every morning.",
      story: {
        title: "The First Cup",
        html: "The <span class=\"u\">coffee</span> was warm in her hands. She stood by the window and watched the street wake up. Steam rose, the room slowly filled with light, and she took her time.",
        loopHtml: "The <span class=\"u\">coffee</span> was warm in her hands. She stood by the window and watched the street wake up.",
        words: "coffee · warm · window",
      },
    },
    wateringcan: {
      word: "watering can",
      ipa: "/ˈwɔːtərɪŋ kæn/",
      pos: "noun",
      zh: "洒水壶",
      def: "A container with a spout, used to water plants.",
      defZh: "带壶嘴、用来浇植物的容器。",
      chunk: "water the mint",
      chunkZh: "给薄荷浇水",
      chunks: [{ t: "spout", zh: "壶嘴" }, { t: "plant", zh: "植物" }, { t: "mint", zh: "薄荷" }],
      from: { en: "From your balcony this morning.", zh: "来自今天早上的阳台。" },
      see: "I watered the mint on the balcony this morning.",
      practice: { cue: "I water the mint ___ a watering can.", answer: "with." },
      alt: "A green watering can in a garden",
      photo: "assets/watering-can.jpg",
      chat: {
        question: "What is growing on your balcony?",
        user: "I water mint by watering can.",
        corrected: "I water the mint with a watering can.",
        correctedHtml: "I water <span class=\"u\">the</span> mint <span class=\"u\">with</span> a watering can.",
        note: "Use “with” for the tool; add “the” before mint.",
        reply: "Your balcony must smell lovely. What else is growing there?",
      },
      example: "I water the mint with a watering can.",
      story: {
        title: "The Balcony",
        html: "The <span class=\"u\">watering can</span> waited by the mint. She filled it slowly and watched the water darken the soil. On the balcony, the morning was green and quiet.",
        loopHtml: "The <span class=\"u\">watering can</span> waited by the mint. She filled it slowly and watched the water darken the soil.",
        words: "watering can · mint · balcony",
      },
    },
    daughter: {
      word: "my daughter",
      ipa: "/maɪ ˈdɔːtər/",
      pos: "phrase",
      zh: "我的女儿",
      def: "The girl in your family.",
      defZh: "你的女儿。",
      chunk: "with my daughter",
      chunkZh: "和我的女儿一起",
      chunks: [{ t: "hand", zh: "手" }, { t: "park", zh: "公园" }, { t: "afternoon", zh: "下午" }],
      from: { en: "From your afternoon together.", zh: "来自你们一起度过的下午。" },
      see: "I walked to the park with my daughter.",
      practice: { cue: "I went to the park ___ my daughter.", answer: "with." },
      alt: "Sunlight through tall trees on a quiet path",
      photo: "assets/forest.jpg",
      chat: {
        question: "What did you do together?",
        user: "I go to park with my daughter yesterday.",
        corrected: "I went to the park with my daughter yesterday.",
        correctedHtml: "I <span class=\"u\">went</span> to <span class=\"u\">the</span> park with my daughter yesterday.",
        note: "go → went; add “the” before park.",
        reply: "That sounds like a good afternoon. What did you do together?",
      },
      example: "I went to the park with my daughter yesterday.",
      story: {
        title: "The Long Way Home",
        html: "Her <span class=\"u\">daughter</span> held her hand on the long way home. They stopped at every tree and named what they saw. By the time they reached the door, the afternoon had become a small story.",
        loopHtml: "Her <span class=\"u\">daughter</span> held her hand on the long way home. They stopped at every tree and named what they saw.",
        words: "daughter · tree · afternoon",
      },
    },
  };

  const ORDER = ["tree", "coffee", "wateringcan", "daughter"];

  const byId = (id) => document.getElementById(id);
  const reduced = window.matchMedia("(prefers-reduced-motion: reduce)");
  const nav = byId("nav");
  const menuToggle = document.querySelector(".menu-toggle");
  const drawer = byId("drawer");
  const toastEl = byId("toast");
  const filmSteps = Array.from(document.querySelectorAll(".film-step"));
  const loopExchanges = Array.from(document.querySelectorAll(".loop-exchange"));
  const filmRail = document.querySelector(".film-rail");
  const navLinks = Array.from(document.querySelectorAll(".nav-links a"));
  const reveals = Array.from(document.querySelectorAll(".reveal"));

  let lang = "en";
  let currentWord = "tree";
  let activePhoto = "a";
  let menuOpen = false;
  let activeScreen = 0;
  let toastTimer = null;
  let speechTimer = null;
  let swapTimer = null;
  let ticking = false;

  function resolve(dict, key) {
    return key.split(".").reduce((value, part) => (
      value == null ? undefined : value[part]
    ), dict);
  }

  function setText(id, text) {
    const el = byId(id);
    if (el) el.textContent = text;
  }

  function setHtml(id, html) {
    const el = byId(id);
    if (el) el.innerHTML = html;
  }

  function plainText(html) {
    const node = document.createElement("div");
    node.innerHTML = html;
    return node.textContent || "";
  }

  function showToast(message) {
    if (!toastEl) return;
    toastEl.textContent = message;
    toastEl.classList.add("is-visible");
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => {
      toastEl.classList.remove("is-visible");
    }, 3600);
  }

  function setPhoto(word) {
    const active = byId("photo-" + activePhoto);
    if (!active) return;
    if (active.getAttribute("src") === word.photo) {
      active.setAttribute("alt", word.alt);
      return;
    }
    const nextName = activePhoto === "a" ? "b" : "a";
    const next = byId("photo-" + nextName);
    let swapped = false;
    const swap = () => {
      if (swapped) return;
      swapped = true;
      next.classList.add("is-active");
      active.classList.remove("is-active");
      active.setAttribute("aria-hidden", "true");
      active.setAttribute("alt", "");
      next.removeAttribute("aria-hidden");
      next.setAttribute("alt", word.alt);
      activePhoto = nextName;
    };
    next.onload = swap;
    next.onerror = swap;
    next.src = word.photo;
    if (next.complete && next.naturalWidth > 0) swap();
  }

  function resetUseThis() {
    const button = byId("use-this");
    const userLine = byId("loop-talk-user");
    const word = WORDS[currentWord];
    if (button) {
      button.textContent = COPY[lang].film.dialogue.useThis;
      button.classList.remove("is-used");
    }
    if (userLine && word) {
      userLine.textContent = word.chat.user;
      userLine.classList.remove("is-corrected");
    }
  }

  function renderLoop(id) {
    const word = WORDS[id];
    if (!word) return;
    setText("loop-see-user", word.see);
    setText("loop-see-word", word.word);
    setText("loop-see-ipa", word.ipa);
    setText("loop-see-meta", word.zh + " · " + word.pos);
    setText("loop-see-def", word.def);
    const wordPlay = byId("loop-word-play");
    if (wordPlay) wordPlay.setAttribute("data-speak", word.word);
    setHtml("loop-talk-corrected", word.chat.correctedHtml || word.chat.corrected);
    setText("loop-talk-note", word.chat.note);
    setText("loop-keep-chunk", word.chunk);
    setText("loop-keep-chunk-zh", word.chunkZh);
    setHtml("loop-keep-chips", word.chunks.map((chunk) => (
      "<li>" + chunk.t + ' <span lang="zh-CN">' + chunk.zh + "</span></li>"
    )).join(""));
    setHtml("loop-practice-cue", word.practice.cue.replace("___", '<span class="loop-blank">___</span>'));
    setText("loop-practice-answer", word.practice.answer);
    setText("loop-story-title", word.story.title);
    const loopStory = word.story.loopHtml || word.story.html;
    setHtml("loop-story-text", loopStory);
    const storyPlay = byId("loop-story-play");
    if (storyPlay) storyPlay.setAttribute("data-speak", plainText(loopStory));
    resetUseThis();
  }

  function renderWord(id, animate) {
    const word = WORDS[id];
    if (!word) return;
    currentWord = id;
    setText("hero-word", word.word);
    setText("hero-ipa", word.ipa);
    setText("hero-pos-zh", word.zh + " · " + word.pos);
    setText("hero-def", word.def);
    setText("hero-def-zh", word.defZh);
    setHtml("hero-chunks", word.chunks.map((chunk) => (
      "<li>" + chunk.t + ' <span lang="zh-CN">' + chunk.zh + "</span></li>"
    )).join(""));
    setText("hero-from", word.from[lang] || word.from.en);
    const heroPlay = byId("hero-play");
    if (heroPlay) {
      heroPlay.setAttribute("data-speak", word.word);
      heroPlay.setAttribute("aria-label", "Play the pronunciation of " + word.word);
    }
    renderLoop(id);
    document.querySelectorAll(".chip").forEach((chip) => {
      chip.classList.toggle("is-active", chip.getAttribute("data-word") === id);
    });
    setPhoto(word);
    if (animate) {
      const card = byId("word-card");
      if (card) {
        card.classList.remove("is-swapping");
        void card.offsetWidth;
        card.classList.add("is-swapping");
        window.clearTimeout(swapTimer);
        swapTimer = window.setTimeout(() => {
          card.classList.remove("is-swapping");
        }, 520);
      }
    }
  }

  function selectWord(id, animate) {
    if (!WORDS[id]) return;
    renderWord(id, animate !== false);
    const input = byId("demo-input");
    if (input) input.value = WORDS[id].word;
    if (window.innerWidth <= 640) {
      const card = byId("word-card");
      if (card) {
        window.setTimeout(() => {
          card.scrollIntoView({ block: "center", behavior: reduced.matches ? "auto" : "smooth" });
        }, 80);
      }
    }
  }

  function applyLang(next, persist) {
    lang = next === "zh" ? "zh" : "en";
    const dict = COPY[lang];
    document.documentElement.lang = lang;
    document.body.dataset.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const value = resolve(dict, el.getAttribute("data-i18n"));
      if (typeof value === "string") el.textContent = value;
    });
    document.querySelectorAll("[data-i18n-html]").forEach((el) => {
      const value = resolve(dict, el.getAttribute("data-i18n-html"));
      if (typeof value === "string") el.innerHTML = value;
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => {
      const value = resolve(dict, el.getAttribute("data-i18n-placeholder"));
      if (typeof value === "string") el.setAttribute("placeholder", value);
    });
    document.querySelectorAll("[data-i18n-aria-label]").forEach((el) => {
      const value = resolve(dict, el.getAttribute("data-i18n-aria-label"));
      if (typeof value === "string") el.setAttribute("aria-label", value);
    });
    document.querySelectorAll(".lang-toggle [data-lang]").forEach((btn) => {
      const active = btn.getAttribute("data-lang") === lang;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-pressed", active ? "true" : "false");
    });
    document.title = dict.meta.title;
    const desc = document.querySelector('meta[name="description"]');
    if (desc) desc.setAttribute("content", dict.meta.description);
    const ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle) ogTitle.setAttribute("content", dict.meta.title);
    const ogDesc = document.querySelector('meta[property="og:description"]');
    if (ogDesc) ogDesc.setAttribute("content", dict.meta.description);
    if (menuToggle) {
      menuToggle.setAttribute("aria-label", dict.nav[menuOpen ? "menuClose" : "menuOpen"]);
    }
    if (persist) {
      try { window.localStorage.setItem("named.lang", lang); } catch (error) {}
      const url = new URL(window.location.href);
      if (lang === "zh") url.searchParams.set("lang", "zh");
      else url.searchParams.delete("lang");
      window.history.replaceState(null, "", url);
    }
    renderWord(currentWord, false);
  }

  function setMenu(open) {
    menuOpen = open;
    if (nav) nav.classList.toggle("is-open", open);
    if (menuToggle) {
      menuToggle.setAttribute("aria-expanded", open ? "true" : "false");
      menuToggle.setAttribute("aria-label", COPY[lang].nav[open ? "menuClose" : "menuOpen"]);
    }
  }

  function updateNav() {
    if (nav) nav.classList.toggle("is-scrolled", window.scrollY > 12);
  }

  function updateSpy() {
    const mark = window.scrollY + 160;
    let current = "";
    navLinks.forEach((link) => {
      const section = byId(link.getAttribute("href").slice(1));
      if (!section) return;
      const top = section.offsetTop - 120;
      const bottom = top + section.offsetHeight;
      if (mark >= top && mark < bottom) current = section.id;
    });
    navLinks.forEach((link) => {
      link.classList.toggle("is-active", link.getAttribute("href") === "#" + current);
    });
  }

  function setActiveExchange(index) {
    activeScreen = index;
    filmSteps.forEach((step, i) => step.classList.toggle("is-active", i === index));
    loopExchanges.forEach((exchange, i) => {
      const active = i === index;
      exchange.classList.toggle("is-active", active);
      exchange.setAttribute("aria-hidden", active ? "false" : "true");
    });
    const count = byId("loop-count");
    if (count) count.textContent = String(index + 1).padStart(2, "0") + " / 05";
  }

  function updateFilm() {
    if (!filmSteps.length) return;
    const anchor = window.innerWidth <= 900 ? window.innerHeight * 0.72 : window.innerHeight * 0.55;
    let active = 0;
    filmSteps.forEach((step, index) => {
      if (step.getBoundingClientRect().top < anchor) active = index;
    });
    if (filmRail) {
      const first = filmSteps[0].getBoundingClientRect();
      const last = filmSteps[filmSteps.length - 1].getBoundingClientRect();
      const total = last.bottom - first.top;
      const progress = total > 0 ? Math.min(1, Math.max(0, (anchor - first.top) / total)) : 0;
      filmRail.style.setProperty("--film-progress", progress.toFixed(3));
    }
    if (active !== activeScreen) setActiveExchange(active);
  }

  function requestUpdate() {
    if (ticking) return;
    ticking = true;
    window.requestAnimationFrame(() => {
      ticking = false;
      updateNav();
      updateSpy();
      updateFilm();
    });
  }

  function resetSpeaking() {
    document.querySelectorAll("[data-speak].is-speaking").forEach((button) => {
      button.classList.remove("is-speaking");
    });
    window.clearTimeout(speechTimer);
  }

  function speak(text, button) {
    if (!("speechSynthesis" in window) || typeof SpeechSynthesisUtterance === "undefined") {
      showToast(COPY[lang].toast.audio);
      return;
    }
    window.speechSynthesis.cancel();
    resetSpeaking();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "en-GB";
    utterance.rate = 0.88;
    const voices = window.speechSynthesis.getVoices() || [];
    const voice = voices.find((item) => /^en[-_]GB/i.test(item.lang))
      || voices.find((item) => /^en[-_]US/i.test(item.lang))
      || voices.find((item) => /^en/i.test(item.lang));
    if (voice) utterance.voice = voice;
    button.classList.add("is-speaking");
    utterance.onend = () => button.classList.remove("is-speaking");
    utterance.onerror = () => button.classList.remove("is-speaking");
    window.speechSynthesis.speak(utterance);
    window.clearTimeout(speechTimer);
    speechTimer = window.setTimeout(resetSpeaking, Math.max(6000, text.length * 90));
  }

  function closeAnnotations() {
    document.querySelectorAll(".annot").forEach((button) => {
      button.setAttribute("aria-expanded", "false");
      const pop = byId(button.getAttribute("aria-controls"));
      if (pop) pop.hidden = true;
    });
  }

  const demo = byId("demo");
  if (demo) {
    demo.addEventListener("submit", (event) => {
      event.preventDefault();
      const input = byId("demo-input");
      if (!input) return;
      const query = input.value.trim().toLowerCase();
      if (!query) {
        input.focus();
        return;
      }
      let id = null;
      if (/tree|树/.test(query)) id = "tree";
      else if (/coffee|咖啡/.test(query)) id = "coffee";
      else if (/water|sprink|洒水|浇/.test(query)) id = "wateringcan";
      else if (/daughter|女儿/.test(query)) id = "daughter";
      if (!id) {
        showToast(COPY[lang].toast.try);
        input.focus();
        return;
      }
      selectWord(id, true);
    });
  }

  document.querySelectorAll(".chip").forEach((chip) => {
    chip.addEventListener("click", () => selectWord(chip.getAttribute("data-word"), true));
  });

  document.querySelectorAll(".lang-toggle [data-lang]").forEach((button) => {
    button.addEventListener("click", () => applyLang(button.getAttribute("data-lang"), true));
  });

  if (menuToggle) {
    menuToggle.addEventListener("click", () => setMenu(!menuOpen));
  }
  if (drawer) {
    drawer.querySelectorAll("a").forEach((link) => {
      link.addEventListener("click", () => setMenu(false));
    });
  }

  const useThis = byId("use-this");
  if (useThis) {
    useThis.addEventListener("click", () => {
      const word = WORDS[currentWord];
      const userLine = byId("loop-talk-user");
      if (word && userLine) {
        userLine.textContent = word.chat.corrected;
        userLine.classList.add("is-corrected");
      }
      useThis.textContent = COPY[lang].film.dialogue.used;
      useThis.classList.add("is-used");
      showToast(COPY[lang].toast.useThis);
    });
  }

  document.querySelectorAll(".annot").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.stopPropagation();
      const pop = byId(button.getAttribute("aria-controls"));
      if (!pop) return;
      const open = pop.hidden;
      closeAnnotations();
      if (open) {
        pop.hidden = false;
        button.setAttribute("aria-expanded", "true");
      }
    });
  });

  document.addEventListener("click", (event) => {
    if (event.target.closest(".annot") || event.target.closest(".annot-pop")) return;
    closeAnnotations();
  });

  document.addEventListener("click", (event) => {
    const button = event.target.closest("[data-speak]");
    if (!button) return;
    event.preventDefault();
    speak(button.getAttribute("data-speak"), button);
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeAnnotations();
      setMenu(false);
    }
  });

  const waitlist = byId("waitlist");
  if (waitlist) {
    const email = byId("email");
    const fieldRow = waitlist.querySelector(".field-row");
    const note = byId("form-note");
    const success = byId("form-success");
    if (email) {
      email.addEventListener("input", () => email.classList.remove("has-error"));
    }
    waitlist.addEventListener("submit", (event) => {
      event.preventDefault();
      if (!email) return;
      const value = email.value.trim();
      const valid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
      if (!valid) {
        email.classList.add("has-error");
        email.focus();
        showToast(COPY[lang].toast.invalid);
        return;
      }
      try { window.localStorage.setItem("named.waitlist", value); } catch (error) {}
      if (fieldRow) fieldRow.style.display = "none";
      if (note) note.style.display = "none";
      if (success) success.hidden = false;
      showToast(COPY[lang].toast.ready);
    });
  }

  if ("IntersectionObserver" in window && !reduced.matches) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    reveals.forEach((el) => observer.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add("is-visible"));
  }

  window.addEventListener("scroll", requestUpdate, { passive: true });
  window.addEventListener("resize", () => {
    requestUpdate();
    if (window.innerWidth > 900 && menuOpen) setMenu(false);
  });

  const params = new URLSearchParams(window.location.search);
  let initial = params.get("lang");
  if (initial !== "zh" && initial !== "en") {
    try {
      const stored = window.localStorage.getItem("named.lang");
      if (stored === "zh" || stored === "en") initial = stored;
    } catch (error) {}
  }
  if (initial !== "zh" && initial !== "en") initial = "en";
  applyLang(initial, false);
  updateNav();
  updateSpy();
  updateFilm();
  window.requestAnimationFrame(() => document.body.classList.add("is-ready"));
})();
