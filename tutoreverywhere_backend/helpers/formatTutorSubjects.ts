// utils/formatUserSubjects.js
function formatUserSubjects(data) {
  // 1. Always return an array, even if empty (never return null)
  if (!Array.isArray(data) || data.length === 0) return [];

  // 2. Group data by unique user identifier (assuming 'id' exists in baseUser)
  // This ensures that if findTutor returns multiple different tutors, 
  // they are not collapsed into a single object.
  const groupedByUser = data.reduce((acc, item) => {
    const { subject, price, ...baseUser } = item;
    const userId = baseUser.id; // Assumes 'id' is the unique key

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