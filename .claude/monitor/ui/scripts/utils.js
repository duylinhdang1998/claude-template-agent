/**
 * Format timestamp to time string
 */
export function formatTime(ts) {
  return ts
    ? new Date(ts).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
    : '--:--';
}

/**
 * Convert agent type to display name
 */
export function formatName(type) {
  if (!type || type === 'unknown') return 'Unknown';
  return type.split('-').map(w => w[0].toUpperCase() + w.slice(1)).join(' ');
}

/**
 * Get initials from name
 */
export function getInitials(name) {
  const words = (name || 'UK').split(/[-\s]+/);
  return words.length >= 2
    ? (words[0][0] + words[1][0]).toUpperCase()
    : name.substring(0, 2).toUpperCase();
}

/**
 * Get color class based on agent type
 */
export function getColorClass(type) {
  if (!type) return 'default';
  if (type.includes('meta')) return 'meta';
  if (type.includes('netflix')) return 'netflix';
  if (type.includes('google')) return 'google';
  if (type.includes('apple')) return 'apple';
  if (type.includes('amazon')) return 'amazon';
  return 'default';
}
