const REGEX_EMAIL = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi;
const REGEX_GDPR_ID = /\d{1,}@gdpr/g;

function getGdprId(gdprString) {
  return gdprString.split("@")[0];
}

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
    ids.push(+getGdprId(idMatch[0]));
  }

  return ids;
};

/**
 *
 * @param {string} originalFile
 * @param {{ [email: string]: number }} emailToIdMap
 * @returns
 */
exports.generateCompliantDoc = function (originalFile, emailToIdMap) {
  let modifiedFile = "";

  let lastIndex = 0;

  let emailMatch;
  while ((emailMatch = REGEX_EMAIL.exec(originalFile)) !== null) {
    const email = emailMatch[0];

    // it's invalid to have an email without an id in the map, as the file
    // should've already been parsed for emails at this point
    const emailId = emailToIdMap[email];
    if (emailId === undefined) {
      throw new Error(`Can't replace email ${email} in doc, no id found`);
    }

    // add text up until start of email
    modifiedFile += originalFile.substring(lastIndex, emailMatch.index);

    // add compliant email
    modifiedFile += `${emailId}@gdpr`;

    // set last index to end of email
    lastIndex = emailMatch.index + email.length;
  }

  // add leftover characters
  modifiedFile += originalFile.substring(lastIndex);

  return modifiedFile;
};

exports.generateOriginalDoc = function (modifiedFile, idToEmailMap) {
  let originalFile = "";

  let lastIndex = 0;

  let idMatch;
  while ((idMatch = REGEX_GDPR_ID.exec(modifiedFile)) !== null) {
    const id = getGdprId(idMatch[0]);

    // it's invalid to have an email without an id in the map, as the file
    // should've already been parsed for emails at this point
    const email = idToEmailMap[id];
    if (email === undefined) {
      throw new Error(`Can't replace gdpr ${id} in doc, no email found`);
    }

    // add text up until start of email
    originalFile += modifiedFile.substring(lastIndex, idMatch.index);

    // add compliant email
    originalFile += email;

    // set last index to end of email
    lastIndex = idMatch.index + idMatch[0].length;
  }

  // add leftover characters
  originalFile += modifiedFile.substring(lastIndex);

  return originalFile;
};
