const EMAIL_REGEX = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi;

/**
 *
 * @param {string} file
 * @returns
 */
exports.extractEmails = function (file) {
  const emails = [];

  let emailMatch;
  while ((emailMatch = EMAIL_REGEX.exec(file)) !== null) {
    emails.push(emailMatch[0]);
  }

  return emails;
};

/**
 *
 * @param {string} file
 * @param {{ [email: string]: number }} emailToIdMap
 * @returns
 */
exports.getCompliantDoc = function (file, emailToIdMap) {
  let modifiedFile = "";

  let lastIndex = 0;

  let emailMatch;
  while ((emailMatch = EMAIL_REGEX.exec(file)) !== null) {
    const email = emailMatch[0];

    // it's invalid to have an email without an id in the map, as the file
    // should've already been parsed for emails at this point
    const emailId = emailToIdMap[email];
    if (emailId === undefined) {
      throw new Error(`Can't replace email ${email} in doc, no id found`);
    }

    // add text up until start of email
    modifiedFile += file.substring(lastIndex, emailMatch.index);

    // add compliant email
    modifiedFile += `${emailId}@gdpr`;

    // set last index to end of email
    lastIndex = emailMatch.index + email.length;
  }

  // add leftover characters
  modifiedFile += file.substring(lastIndex);

  return modifiedFile;
};
