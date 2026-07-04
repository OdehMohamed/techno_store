/**
 * Shared helpers used by multiple migration scripts, so the definition of
 * "has sensitive data" and the field list stays in exactly one place.
 */

const SENSITIVE_FIELDS = ['pin', 'patternLock', 'notesHidden'];

function hasSensitiveData(data) {
  return Boolean(
    (data.pin && data.pin.length > 0) ||
      (Array.isArray(data.patternLock) && data.patternLock.length > 0) ||
      (data.notesHidden && data.notesHidden.length > 0),
  );
}

function extractSensitiveData(data) {
  const result = {};
  for (const field of SENSITIVE_FIELDS) {
    if (data[field] !== undefined) result[field] = data[field];
  }
  return result;
}

function deepEqual(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

module.exports = { SENSITIVE_FIELDS, hasSensitiveData, extractSensitiveData, deepEqual };
