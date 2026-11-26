(function () {
  "use strict";

  const COPY = {
    en: {
      meta: {
        title: "Named · Keep the words you meet",
        description:
          "Named helps you keep the English words you meet. Name what you notice, talk about it, and meet the word again in practice and in a story from your own days.",
      },
      skip: "Skip to content",
      nav: {
        primary: "Primary",
        loop: "The loop",
        companion: "Companion",
        features: "Features",
        privacy: "Privacy",
        home: "Named home",
        language: "Language",
        github: "GitHub",
        menuOpen: "Open menu",
        menuClose: "Close menu",
      },
      hero: {
        pill: "A companion for your English",
        title: "Keep the words<br><em>you meet.</em>",
        lede: "Name what you notice. Talk it through. Your companion turns the moment into English you actually use, then brings it back in practice and in a story.",
        pill1: "One word",
        pill2: "Kept",
        pill3: "Met again",
        fact1: "iOS + Android",
        fact2: "Private by default",
        fact3: "No streaks",
      },
      problem: {
        pill: "Problem",
        title: "You already know the word.<br><em>You just don’t keep it.</em>",
        lede: "You notice something real. The word never stays with you.",
        card1: { title: "You see it, then lose it.", desc: "A tree, a word, a moment. By the evening, it is gone." },
        card2: { title: "Practice feels like a test.", desc: "Scores and streaks turn a small habit into a chore." },
        card3: { title: "Nothing ties it to your life.", desc: "Words live in an app, not in your days." },
      },
      solution: {
        pill: "Solution",
        title: "One companion.<br><em>One loop.</em>",
        lede: "Name what you notice, talk it through, keep the word, and meet it again.",
        link: "See the loop",
        phoneLine: "Morning. What did you notice today?",
        stat1: "Words kept",
        stat2: "Talks",
        stat3: "Stories",
        stat4: "Streaks",
        zeroNote: "No scores. No pressure.",
      },
      why: {
        pill: "Why",
        title: "Why it works differently.",
        lede: "A small habit only survives if it belongs to your day.",
        card1: { title: "It starts from your life.", desc: "A photo, a sentence, a moment. The word comes from what you already noticed." },
        card2: { title: "It corrects quietly.", desc: "A more natural sentence, not a red pen. The conversation keeps going." },
        card3: {
          title: "It remembers the thread.",
          desc: "Your words, your recurring mistakes, and the moments you kept come back when they matter.",
        },
      },
      how: {
        pill: "How it works",
        title: "From a word to a story in five quiet moves.",
        lede: "No units to finish, no streak to protect.",
        step1: { title: "See it.", desc: "Name what you noticed." },
        step2: { title: "Say it.", desc: "Talk it through. A quiet correction follows." },
        step3: { title: "Keep it.", desc: "Sound, meaning, and one usable chunk." },
        step4: { title: "Practice it.", desc: "One small return. No score." },
        step5: { title: "Meet it again.", desc: "A story made from your words." },
      },
      features: {
        pill: "Features",
        title: "Everything you need to keep the word.",
        lede: "Six small tools, one loop.",
        f1: { title: "Discover", desc: "A word, a sentence, or a photo becomes one clear card." },
        f2: { title: "Talk", desc: "Natural replies, quiet corrections, useful notes." },
        f3: { title: "Words", desc: "Sound, meaning, and one chunk you can use." },
        f4: { title: "Practice", desc: "A short return, without a score." },
        f5: { title: "Daily", desc: "A story written from the words you kept." },
        f6: { title: "Ask", desc: "A direct answer, with the context you were reading." },
        askQ: "“What’s the difference between say and tell?”",
        askA: "Say is the words you speak. Tell needs a listener: tell me, tell her.",
      },
      companion: {
        alt: "Momo, a small black cat",
        pill: "Companion",
        title: "Meet your companion.",
        lede: "A small black cat who learns English with you. You give it a name.",
        pill1: "You named me.",
        pill2: "I remember.",
        name: "Momo",
        role: "Your companion",
        trait1: { title: "You name it.", desc: "Momo, Pip, Nori. The name is yours, and it can change." },
        trait2: { title: "It remembers.", desc: "Your words, the mistakes you make twice, and the moments you kept." },
        trait3: { title: "It speaks first.", desc: "A small line on the timeline, or the first message in Talk." },
        note: "A character, not a tutor.",
        expressionsAria: "Companion expressions",
      },
      story: {
        pill: "A story",
        title: "Your words<br><em>become a story.</em>",
        lede: "Every day, your companion writes a short story from the words you kept.",
        quote: "Not a quiz. Not a streak. Just a story.",
        date: "Mon, Nov 23",
        listen: "Listen",
        title2: "The Tree by the Path",
        foot: "Written from your words",
      },
      privacy: {
        pill: "Privacy",
        title: "Private by design.",
        lede: "Your words and moments are yours. Named checks and saves; the model can change without changing your data.",
        stat1: "focused agents",
        stat2: "product surfaces",
        stat3: "shared runtime",
        fact1: { title: "Your data stays yours.", desc: "Words, talks, and stories are account-scoped and deleted with your account." },
        fact2: {
          title: "Checked before saving.",
          desc: "Agents return structured results. The backend validates them before they touch your data.",
        },
        fact3: {
          title: "One model, replaceable.",
          desc: "Twelve focused agents share one runtime. Swapping the model does not rewrite the product.",
        },
        link: "Read the full agent system",
      },
      footer: {
        tagline: "One word, one story.",
        support: "A little cat, a word you keep, and a story from your own days.",
        nav: "Footer",
        note: "© 2026 Named",
        top: "Back to top",
      },
      mock: {
        timeline: "Timeline",
        from: "From your walk in the park.",
        talk: "Talk about it",
        sayNote: "sit → sat; add “the” before tree.",
        fromWords: "From your words",
      },
    },
    zh: {
      meta: {
        title: "Named · 留下你遇见的词",
        description: "Named 帮你留下遇见的英语单词。命名你看见的东西，聊一聊，再在练习和故事里遇见它。",
      },
      skip: "跳到内容",
      nav: {
        primary: "主导航",
        loop: "产品循环",
        companion: "伙伴",
        features: "功能",
        privacy: "隐私",
        home: "Named 首页",
        language: "语言",
        github: "GitHub",
        menuOpen: "打开菜单",
        menuClose: "关闭菜单",
      },
      hero: {
        pill: "你的英语伙伴",
        title: "把遇见的词，<br><em>留下来。</em>",
        lede: "命名你看见的东西，聊一聊。你的伙伴把瞬间变成真正用得上的英语，再在练习和故事里把它带回来。",
        pill1: "一个词",
        pill2: "留下了",
        pill3: "再遇见",
        fact1: "iOS + Android",
        fact2: "默认私密",
        fact3: "不打卡",
      },
      problem: {
        pill: "问题",
        title: "你已经认识这个词。<br><em>只是没有留下它。</em>",
        lede: "你注意到真实的东西。但那个词没有留下来。",
        card1: { title: "看见了，又丢了。", desc: "一棵树、一个词、一个瞬间。到了晚上，它就没了。" },
        card2: { title: "练习像考试。", desc: "分数和连胜，把一个小习惯变成任务。" },
        card3: { title: "和你的生活没有关系。", desc: "词留在 App 里，没有留在你的日子里。" },
      },
      solution: {
        pill: "方案",
        title: "一个伙伴。<br><em>一个循环。</em>",
        lede: "命名你看见的，聊一聊，把词留下，再遇见它。",
        link: "看看产品循环",
        phoneLine: "早上好。今天，你注意到了什么？",
        stat1: "留下的词",
        stat2: "对话",
        stat3: "故事",
        stat4: "连胜",
        zeroNote: "没有分数，也没有压力。",
      },
      why: {
        pill: "为什么",
        title: "为什么它不一样。",
        lede: "小习惯只有长在你的日子里，才会留下来。",
        card1: { title: "它从你的生活开始。", desc: "一张照片、一句话、一个瞬间。词来自你已经注意到的东西。" },
        card2: { title: "它安静地纠正。", desc: "给你更自然的句子，不是红笔批改。对话继续。" },
        card3: { title: "它记得这条线。", desc: "你的词、重复的错、留下的瞬间，会在需要的时候回来。" },
      },
      how: {
        pill: "怎么运作",
        title: "从一个词到一个故事，五个安静的动作。",
        lede: "没有要完成的单元，也没有要保护的连胜。",
        step1: { title: "看见。", desc: "命名你注意到的东西。" },
        step2: { title: "说出。", desc: "聊一聊，然后是一句安静的纠正。" },
        step3: { title: "留下。", desc: "发音、意思，和一个能用的搭配。" },
        step4: { title: "练习。", desc: "一次小小的回来。没有分数。" },
        step5: { title: "再遇见。", desc: "一个用你的词写成的故事。" },
      },
      features: {
        pill: "功能",
        title: "留下一个词，需要的都在这里。",
        lede: "六个小工具，一个循环。",
        f1: { title: "发现", desc: "一个词、一句话，或一张照片，变成一张清楚的卡。" },
        f2: { title: "对话", desc: "自然的回复，安静的纠正，有用的标注。" },
        f3: { title: "词语", desc: "发音、意思，和一个能用的搭配。" },
        f4: { title: "练习", desc: "一次短短的回来，没有分数。" },
        f5: { title: "每日", desc: "用你留下的词写成的故事。" },
        f6: { title: "提问", desc: "直接的回答，带着你正在读的上下文。" },
        askQ: "“say 和 tell 有什么区别？”",
        askA: "say 是你说出来的话。tell 需要一个听的人：tell me，tell her。",
      },
      companion: {
        alt: "Momo，一只小黑猫",
        pill: "伙伴",
        title: "认识你的伙伴。",
        lede: "一只和你一起学英语的小黑猫。你给它取名。",
        pill1: "你给我取了名字。",
        pill2: "我记得。",
        name: "Momo",
        role: "你的伙伴",
        trait1: { title: "你给它取名。", desc: "Momo、Pip、Nori。名字是你的，也可以改。" },
        trait2: { title: "它会记得。", desc: "你的词、你重复犯的错，还有你留下的瞬间。" },
        trait3: { title: "它会先开口。", desc: "时间线上的一句话，或 Talk 里的第一句。" },
        note: "它是一个角色，不是老师。",
        expressionsAria: "伙伴的表情",
      },
      story: {
        pill: "一个故事",
        title: "你的词，<br><em>变成一个故事。</em>",
        lede: "每天，你的伙伴用你留下的词写一个短故事。",
        quote: "不是测验，也不是打卡。只是一个故事。",
        date: "11 月 23 日，周一",
        listen: "朗读",
        title2: "小路旁的树",
        foot: "用你的词写成",
      },
      privacy: {
        pill: "隐私",
        title: "默认私密。",
        lede: "你的词和瞬间属于你。Named 校验后保存；换模型不会动你的数据。",
        stat1: "专一 agent",
        stat2: "产品场景",
        stat3: "共享运行时",
        fact1: { title: "你的数据属于你。", desc: "词语、对话和故事都跟着账号，随账号一起删除。" },
        fact2: { title: "先校验，再保存。", desc: "agent 返回结构化结果，后端校验后才写进你的数据。" },
        fact3: { title: "一个模型，可以替换。", desc: "十二个专一 agent 共用一个运行时。换模型不需要重写产品。" },
        link: "阅读完整的 agent 体系",
      },
      footer: {
        tagline: "一个词，一个故事。",
        support: "一只小猫，一个留下的词，一个用你的日子写成的故事。",
        nav: "页脚",
        note: "© 2026 Named",
        top: "回到顶部",
      },
      mock: {
        timeline: "时间线",
        from: "来自你在公园的散步。",
        talk: "聊聊它",
        sayNote: "sit → sat；tree 前加 the。",
        fromWords: "用你的词写成",
      },
    },
  };

  const byId = (id) => document.getElementById(id);
  const resolve = (obj, path) => path.split(".").reduce((value, key) => (value == null ? value : value[key]), obj);

  const nav = byId("nav");
  const menuToggle = document.querySelector(".menu-toggle");
  let lang = "en";
  let menuOpen = false;

  function applyLang(next, persist) {
    if (!COPY[next]) next = "en";
    lang = next;
    const dict = COPY[next];

    document.documentElement.lang = next === "zh" ? "zh-CN" : "en";
    document.body.setAttribute("data-lang", next);

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
      btn.setAttribute("aria-pressed", btn.getAttribute("data-lang") === next ? "true" : "false");
    });

    if (menuToggle) {
      menuToggle.setAttribute("aria-label", dict.nav[menuOpen ? "menuClose" : "menuOpen"]);
    }

    const title = document.querySelector("title");
    if (title) title.textContent = dict.meta.title;

    const selectors = [
      ['meta[name="description"]', "description"],
      ['meta[property="og:title"]', "title"],
      ['meta[property="og:description"]', "description"],
      ['meta[name="twitter:title"]', "title"],
      ['meta[name="twitter:description"]', "description"],
    ];

    selectors.forEach(([selector, key]) => {
      const el = document.querySelector(selector);
      if (el) el.setAttribute("content", dict.meta[key]);
    });

    if (persist) {
      try {
        window.localStorage.setItem("named.lang", next);
      } catch (error) {
        /* storage is optional */
      }
    }
  }

  function setMenu(open) {
    if (!menuToggle || !nav) return;
    menuOpen = open;
    nav.classList.toggle("is-open", open);
    menuToggle.setAttribute("aria-expanded", open ? "true" : "false");
    menuToggle.setAttribute("aria-label", COPY[lang].nav[open ? "menuClose" : "menuOpen"]);
  }

  document.querySelectorAll(".lang-toggle [data-lang]").forEach((btn) => {
    btn.addEventListener("click", () => applyLang(btn.getAttribute("data-lang"), true));
  });

  if (menuToggle) {
    menuToggle.addEventListener("click", () => setMenu(!menuOpen));
  }

  document.querySelectorAll(".nav-drawer a").forEach((link) => {
    link.addEventListener("click", () => setMenu(false));
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && menuOpen) setMenu(false);
  });

  const updateNav = () => {
    if (nav) nav.classList.toggle("is-scrolled", window.scrollY > 8);
  };
  window.addEventListener("scroll", updateNav, { passive: true });
  updateNav();

  document.querySelectorAll("[data-speak]").forEach((el) => {
    el.addEventListener("click", () => {
      const text = el.getAttribute("data-speak");
      if (!text || !("speechSynthesis" in window)) return;
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = "en-US";
      window.speechSynthesis.speak(utterance);
    });
  });

  const reveals = Array.from(document.querySelectorAll(".reveal"));
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if ("IntersectionObserver" in window && !reduceMotion) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        });
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.08 },
    );
    reveals.forEach((el) => observer.observe(el));
  } else {
    reveals.forEach((el) => el.classList.add("is-visible"));
  }

  let initial = "en";
  try {
    const stored = window.localStorage.getItem("named.lang");
    if (stored === "en" || stored === "zh") {
      initial = stored;
    } else if (navigator.language && navigator.language.toLowerCase().startsWith("zh")) {
      initial = "zh";
    }
  } catch (error) {
    /* storage is optional */
  }

  applyLang(initial, false);
})();
