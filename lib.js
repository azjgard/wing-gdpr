const EMAIL_REGEX = /([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/gi;

exports.extractEmails = function (file) {
  const emails = [];

  let parsedEmail;
  while ((parsedEmail = EMAIL_REGEX.exec(file)) !== null) {
    emails.push(parsedEmail[0]);
  }

  return emails;
};
