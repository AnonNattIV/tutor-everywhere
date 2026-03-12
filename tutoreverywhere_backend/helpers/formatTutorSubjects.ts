// utils/formatUserSubjects.js
function formatUserSubjects(data) {
  // 1. Always return an array, even if empty (never return null)
  if (!Array.isArray(data) || data.length === 0) return [];

  // 2. Group data by tutor user id.
  // Backend query returns `user_uuid` (not `id`), so we must key by that field.
  const groupedByUser = data.reduce((acc, item) => {
    const { subject, price, ...baseUser } = item;
    const userId = (
      baseUser.user_uuid ??
      baseUser.userId ??
      baseUser.id
    )?.toString?.();
    if (!userId) {
      return acc;
    }

    if (!acc[userId]) {
      acc[userId] = {
        ...baseUser,
        subject_by_price: {}
      };
    }

    // Add subject and price to the specific user's list
    acc[userId].subject_by_price[subject] = price;

    return acc;
  }, {});

  // 3. Convert the grouped object back into a list (array)
  return Object.values(groupedByUser);
}

export default formatUserSubjects;
