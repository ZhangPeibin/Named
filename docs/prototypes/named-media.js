window.NamedMedia = (() => {
  const paths = {
    back: '<path d="m14 5-7 7 7 7"/>', arrow: '<path d="m9 5 7 7-7 7"/>',
    plus: '<path d="M12 5v14M5 12h14"/>', close: '<path d="m6 6 12 12M18 6 6 18"/>',
    home: '<path d="m3 10 9-7 9 7v10H3V10Zm6 10v-7h6v7"/>',
    world: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c-5 5-5 13 0 18 5-5 5-13 0-18Z"/>',
    camera: '<rect x="3" y="6" width="18" height="14" rx="3"/><circle cx="12" cy="13" r="4"/><path d="m8 6 2-3h4l2 3"/>',
    image: '<rect x="3" y="3" width="18" height="18" rx="4"/><circle cx="8" cy="8" r="1.5"/><path d="m3 17 6-6 4 4 4-5 4 5"/>',
    mic: '<rect x="9" y="2" width="6" height="13" rx="3"/><path d="M5 10v2a7 7 0 0 0 14 0v-2M12 19v3M8 22h8"/>',
    sound: '<path d="m11 5-5 4H3v6h3l5 4V5ZM15 8c3 2 3 6 0 8M18 5c5 4 5 10 0 14"/>',
    chat: '<path d="M21 11a9 9 0 1 0-15 7l-3 4 7-2a9 9 0 0 0 11-9Z"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
    leaf: '<path d="M5 19C0 7 11 2 21 3c1 10-4 20-16 16Zm0 0L17 7"/>',
    book: '<path d="M12 6C8 3 3 4 3 4v15s5-1 9 2c4-3 9-2 9-2V4s-5-1-9 2Zm0 0v15"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    check: '<path d="m5 12 4 4L20 5"/>', edit: '<path d="m15 4 5 5M4 20l5-1L21 7l-4-4L5 15l-1 5Z"/>',
    settings: '<path d="M4 7h16M4 17h16"/><circle cx="9" cy="7" r="3"/><circle cx="15" cy="17" r="3"/>',
    pause: '<path d="M8 5v14M16 5v14"/>', play: '<path d="m8 4 12 8-12 8V4Z"/>',
    retry: '<path d="M20 8a9 9 0 1 0 1 8M20 3v6h-6"/>', send: '<path d="m5 12 7-7 7 7M12 5v15"/>',
    sparkle: '<path d="m12 3 3 6 6 3-6 3-3 6-3-6-6-3 6-3 3-6Z"/>',
    flag: '<path d="M5 22V3c5-5 9 5 15 0v11c-6 5-10-5-15 0"/>',
    pin: '<path d="M19 10c0 5-7 11-7 11S5 15 5 10a7 7 0 1 1 14 0Z"/><circle cx="12" cy="10" r="2"/>',
    user: '<circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/>',
    compass: '<circle cx="12" cy="12" r="9"/><path d="m16 8-3 5-5 3 3-5 5-3Z"/>',
    moon: '<path d="M20 14A8 8 0 0 1 10 4 9 9 0 1 0 20 14Z"/>',
  };
  const icon = (name, size = 20) => `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name] || paths.leaf}</svg>`;
  const images = { tree: ['assets/forest.jpg', '阳光穿过林间树木'], can: ['assets/watering-can.jpg', '真实生活中的洒水壶'], coffee: ['assets/coffee.jpg', '日常生活中的咖啡'] };
  function scene(type = 'tree') {
    if (type === 'moment') return `<div class="moment-placeholder">${icon('chat', 34)}<span>来自你的一段生活</span></div>`;
    const [src, alt] = images[type] || images.tree;
    return `<img class="scene-photo photo-${type}" src="${src}" alt="${alt}" width="1200" height="800">`;
  }
  const avatar = () => '<img class="companion-photo" src="assets/companion.jpg" alt="Milo 虚拟伙伴的示例人物形象" width="900" height="1350">';
  return { icon, scene, avatar };
})();
