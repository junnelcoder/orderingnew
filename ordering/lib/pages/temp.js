let { username, password } = req.body;

  let x = 0;
  let letter = "";

  if (password.length !== 0) {
    while (x < password.length) {
      var n = password.charCodeAt(x) + (x + 1);
      letter = letter + String.fromCharCode(n);
      x++;
    }
  }

  password = letter;

  const validateUser = await executeQueryWithParams(
    "select rtrim(ltrim(user_id)) as user_id from user_access WHERE user_id = @username AND user_password = @password",
    { username, password }
  );

  if (validateUser.length == 0) {
    return res.sendStatus(401);
  }


  req.session.user = validateUser[0].user_id;

  res.sendStatus(200);