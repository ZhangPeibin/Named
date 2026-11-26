(function () {
  "use strict";

  const COPY = {
    en: {
      meta: {
        title: "Named · A little cat who learns English with you",
        description:
          "Named gives you a small black cat who learns English with you. Name what you notice, talk about it, keep the word, and meet it again in a story made from your days.",
      },
      skip: "Skip to content",
      nav: {
        home: "Named home",
        primary: "Primary",
        language: "Language",
        loop: "The loop",
        companion: "Companion",
        story: "A story",
        privacy: "Privacy",
        early: "Get early access",
        github: "GitHub",
        menuOpen: "Open menu",
        menuClose: "Close menu",
      },
      hero: {
        eyebrow: "A companion for your English",
        title: "A little cat<br><em>who learns<br>with you.</em>",
        lede: "Name what you notice. Talk about it. Keep the word. Your companion turns each moment into English you actually use.",
        cta: "Get early access",
        see: "See the loop",
        fact1: "iOS + Android",
        fact2: "Private by default",
        fact3: "No streaks",
        altCat: "Momo, your companion",
        presenceName: "Momo",
        presence: "Morning. What did you notice today?",
        composer: "What did you see today?",
      },
      loop: {
        eyebrow: "The loop",
        title: "One word,<br><em>five quiet moves.</em>",
        lede: "See it, say it, keep it, practice it, meet it again. No units to finish, no streak to protect.",
        tablist: "The five steps",
        step1: { title: "See", desc: "Name what you noticed." },
        step2: { title: "Say", desc: "Talk it through." },
        step3: { title: "Keep", desc: "Save the word you used." },
        step4: { title: "Practice", desc: "Use it once more." },
        step5: { title: "Meet again", desc: "Read it in a new story." },
      },
      companion: {
        alt: "Momo, a small black cat",
        name: "Momo",
        role: "Your companion",
        eyebrow: "Your companion",
        title: "It stays with you.",
        lede: "A small black cat who learns English with you. You give it a name. It remembers your words, the mistakes you make twice, and the moments you kept.",
        trait1: { title: "You name it.", desc: "Momo, Pip, Nori. The name is yours, and it can change." },
        trait2: { title: "It remembers.", desc: "Your words, your recurring mistakes, and the moments you saved." },
        trait3: { title: "It speaks first.", desc: "A small line on the timeline, or the first message in Talk." },
        note: "A character, not a tutor.",
      },
      story: {
        eyebrow: "A story",
        title: "Your words<br><em>become a story.</em>",
        lede: "Every day, your companion writes a short story from the words you kept. Read it, or let it read to you.",
        quote: "Not a quiz. Not a streak. Just a story.",
        date: "Mon, Nov 23",
        listen: "Listen",
        title2: "The Tree by the Path",
        foot: "Written from your words",
      },
      privacy: {
        eyebrow: "Privacy",
        title: "Private by design.",
        lede: "Your words and moments are yours. The AI suggests; Named checks and saves. The model can change without changing your data.",
        stat: "12 focused agents · 6 surfaces · 1 shared runtime",
        link: "Read the full agent system",
        fact1: {
          title: "Your data stays yours.",
          desc: "Words, talks, and stories are account-scoped and deleted with your account.",
        },
        fact2: {
          title: "Checked before saving.",
          desc: "Agents return structured results. The backend validates them before they touch your data.",
        },
        fact3: {
          title: "One model, replaceable.",
          desc: "Twelve focused agents share one runtime. Swapping the model does not rewrite the product.",
        },
      },
      cta: {
        catAlt: "Momo, your companion",
        eyebrow: "Begin",
        title: "Start with<br><em>one word.</em>",
        lede: "Named is coming to iOS and Android. Leave a note and we will write when it is ready.",
        emailLabel: "Email address",
        placeholder: "you@example.com",
        button: "Join the waitlist",
        note: "One email when it is ready. No noise.",
        success: "You are on the list. We will write when Named is ready.",
      },
      footer: {
        tagline: "One word, one story.",
        support: "A little cat, a word you keep, and a story from your own days.",
        note: "© 2026 Named",
        top: "Back to top",
      },
      toast: {
        invalid: "Please enter a valid email address.",
      },
    },
    zh: {
      meta: {
        title: "Named · 一只陪你学英语的小猫",
        description: "Named 给你一只小黑猫。它陪你命名看见的东西，聊一聊，把词留下，再在你的故事里遇见它。",
      },
      skip: "跳到内容",
      nav: {
        home: "Named 首页",
        primary: "主导航",
        language: "语言",
        loop: "产品循环",
        companion: "伙伴",
        story: "故事",
        privacy: "隐私",
        early: "预约体验",
        github: "GitHub",
        menuOpen: "打开菜单",
        menuClose: "关闭菜单",
      },
      hero: {
        eyebrow: "你的英语伙伴",
        title: "一只小黑猫，<br><em>陪你学英语。</em>",
        lede: "命名你看见的东西，聊一聊，把词留下。你的伙伴把每个瞬间变成真正用得上的英语。",
        cta: "预约体验",
        see: "看看产品循环",
        fact1: "iOS + Android",
        fact2: "默认私密",
        fact3: "不打卡",
        altCat: "Momo，你的伙伴",
        presenceName: "Momo",
        presence: "早上好。今天，你注意到了什么？",
        composer: "今天，你看见了什么？",
      },
      loop: {
        eyebrow: "产品循环",
        title: "一个词，<br><em>五个安静的动作。</em>",
        lede: "看见、说出、留下、练习、再遇见。没有要完成的单元，也没有要保护的连胜。",
        tablist: "五个步骤",
        step1: { title: "看见", desc: "命名你注意到的东西。" },
        step2: { title: "说出", desc: "聊一聊。" },
        step3: { title: "留下", desc: "保存你用过的词。" },
        step4: { title: "练习", desc: "再用一次。" },
        step5: { title: "再遇见", desc: "在新的故事里读到它。" },
      },
      companion: {
        alt: "Momo，一只小黑猫",
        name: "Momo",
        role: "你的伙伴",
        eyebrow: "你的伙伴",
        title: "它会一直在。",
        lede: "一只和你一起学英语的小黑猫。你给它取名。它记得你的词、你重复犯的错，还有你留下的瞬间。",
        trait1: { title: "你给它取名。", desc: "Momo、Pip、Nori。名字是你的，也可以改。" },
        trait2: { title: "它会记得。", desc: "你的词、反复出现的错，还有你留下的瞬间。" },
        trait3: { title: "它会先开口。", desc: "时间线上的一句话，或 Talk 里的第一句。" },
        note: "它是一个角色，不是老师。",
      },
      story: {
        eyebrow: "一个故事",
        title: "你的词，<br><em>变成一个故事。</em>",
        lede: "每天，你的伙伴用你留下的词写一个短故事。读它，或者让它读给你听。",
        quote: "不是测验，也不是打卡。只是一个故事。",
        date: "11 月 23 日，周一",
        listen: "朗读",
        title2: "小路旁的树",
        foot: "用你的词写成",
      },
      privacy: {
        eyebrow: "隐私",
        title: "默认私密。",
        lede: "你的词和瞬间属于你。AI 提建议，Named 校验后保存。换模型不会动你的数据。",
        stat: "12 个专一 agent · 6 个产品场景 · 1 个共享运行时",
        link: "阅读完整的 agent 体系",
        fact1: { title: "你的数据属于你。", desc: "词语、对话和故事都跟着账号，随账号一起删除。" },
        fact2: { title: "先校验，再保存。", desc: "agent 返回结构化结果，后端校验后才写进你的数据。" },
        fact3: { title: "一个模型，可以替换。", desc: "十二个专一 agent 共用一个运行时。换模型不需要重写产品。" },
      },
      cta: {
        catAlt: "Momo，你的伙伴",
        eyebrow: "开始",
        title: "从一个词<br><em>开始。</em>",
        lede: "Named 即将来到 iOS 和 Android。留下邮箱，准备好时我们会写信告诉你。",
        emailLabel: "邮箱地址",
        placeholder: "you@example.com",
        button: "加入等待名单",
        note: "准备好时只写一封邮件，不打扰。",
        success: "你已在名单里。Named 准备好时，我们会写信告诉你。",
      },
      footer: {
        tagline: "一个词，一个故事。",
        support: "一只小猫，一个留下的词，一个用你的日子写成的故事。",
        note: "© 2026 Named",
        top: "回到顶部",
      },
      toast: {
        invalid: "请输入有效的邮箱地址。",
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

  function setStep(index) {
    const tabs = Array.from(document.querySelectorAll(".loop-tab"));
    const panels = Array.from(document.querySelectorAll(".loop-panel"));

    tabs.forEach((tab, i) => {
      const active = i === index;
      tab.classList.toggle("is-active", active);
      tab.setAttribute("aria-selected", active ? "true" : "false");
      tab.setAttribute("tabindex", active ? "0" : "-1");
    });

    panels.forEach((panel, i) => {
      const active = i === index;
      panel.classList.toggle("is-active", active);
      panel.hidden = !active;
    });
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

  const tabs = Array.from(document.querySelectorAll(".loop-tab"));
  tabs.forEach((tab, index) => {
    tab.addEventListener("click", () => setStep(index));
    tab.addEventListener("keydown", (event) => {
      const isNext = event.key === "ArrowRight" || event.key === "ArrowDown";
      const isPrev = event.key === "ArrowLeft" || event.key === "ArrowUp";
      if (!isNext && !isPrev) return;
      event.preventDefault();
      const next = (index + (isNext ? 1 : -1) + tabs.length) % tabs.length;
      tabs[next].focus();
      setStep(next);
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

  const waitlist = byId("waitlist");
  if (waitlist) {
    const note = byId("form-note");
    const success = byId("form-success");

    waitlist.addEventListener("submit", (event) => {
      event.preventDefault();
      const input = byId("email");
      const value = input ? input.value.trim() : "";
      const valid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);

      if (!valid) {
        if (note) {
          note.textContent = COPY[lang].toast.invalid;
          note.hidden = false;
        }
        if (input) input.focus();
        return;
      }

      try {
        window.localStorage.setItem("named.waitlist", value);
      } catch (error) {
        /* storage is optional */
      }

      if (note) note.hidden = true;
      if (success) success.hidden = false;
      waitlist.reset();
    });
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
  setStep(0);
})();
