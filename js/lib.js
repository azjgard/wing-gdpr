const REGEX_EMAIL = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi;
const REGEX_GDPR_ID = /\d{1,}@gdpr/g;

/**
 * @param {string} file
 * @returns an array of email addresses contained in `file`
 */
exports.extractEmails = function (file) {
  const emails = [];

  let emailMatch;
  while ((emailMatch = REGEX_EMAIL.exec(file)) !== null) {
    emails.push(emailMatch[0]);
  }

  return emails;
};

/**
 * @param {string} file
 * @returns an array of GDPR ids contained in `file`
 */
exports.extractGdprIds = function (file) {
  const ids = [];

  let idMatch;
  while ((idMatch = REGEX_GDPR_ID.exec(file)) !== null) {
    ids.push(+idMatch[0].replace("@gdpr", ""));
  }

  return ids;
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
  while ((emailMatch = REGEX_EMAIL.exec(file)) !== null) {
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
