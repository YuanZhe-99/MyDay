/// Shared emoji candidates for the task emoji picker.
///
/// Purpose: Hold the flat emoji candidate list shown in the task emoji picker grid.
/// Inputs: None.
/// Returns: None (top-level constant).
/// Side effects: None.
/// Notes: Order is the picker order: the original 32 first, then everyday groups (arrows, mail,
/// delivery, money, events, health, home, pets and plants, tools, transport, leisure, food, time,
/// misc). Shared by `AddTaskDialog` and `EditTaskDialog`. Every entry must be a single grapheme
/// cluster and must also appear in `emojiKeywordTable` (both are enforced by tests).
const List<String> commonTaskEmojis = [
  // Original set (v0.1.x).
  '📝', '🏃', '📖', '💪', '🧘', '🎯', '📧', '☎️',
  '🛒', '🧹', '👨‍💻', '✍️', '📅', '🔧', '🎓', '💼',
  '🍳', '🚗', '💊', '🐕', '🏠', '🎵', '🎨', '📸',
  '💡', '🔬', '📊', '🗂️', '✈️', '💤', '🏋️', '🧑‍🍳',
  // Arrows.
  '➡️', '⬅️', '⬆️', '⬇️', '🔄', '↩️',
  // Mail.
  '✉️', '📩', '📨', '📮',
  // Delivery.
  '📦', '🚚', '📬',
  // Money.
  '💰', '💳', '🏦', '🧾',
  // Gifts and events.
  '🎁', '🎂', '🎉',
  // Health and family.
  '🏥', '🩺', '💉', '🦷', '🧑‍⚕️', '👶',
  // Home chores.
  '🧺', '🧼', '🚿', '🛁', '🛏️',
  // Pets and plants.
  '🐈', '🌱', '🪴',
  // Tools.
  '🛠️', '🔑',
  // Transport.
  '🚲', '🚌', '🚆', '⛽', '🅿️',
  // Leisure.
  '🎮', '🎬', '📺', '🎧',
  // Food.
  '☕', '🍽️', '🍎', '🥗',
  // Time and pins.
  '🕐', '⏰', '📌', '📎',
  // Misc.
  '🗑️', '♻️', '🔋', '📱', '💻', '🖨️', '🏢', '🏫',
  '⛪', '❤️', '⭐', '✅', '❗',
];
