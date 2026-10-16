#!/bin/bash

secret_number=$((RANDOM % 1000 + 1))
number_of_guesses=0
PSQL=(psql --username=freecodecamp --dbname=number_guess -q -t --no-align -v ON_ERROR_STOP=1)

echo "Enter your username:"
read -r username

user_record=$(printf "%s\n" "SELECT users.username || '|' || users.user_id || '|' || COUNT(games.game_id) || '|' || COALESCE(MIN(games.number_guesses), 0) FROM users LEFT JOIN games USING (user_id) WHERE username = :'username' GROUP BY users.user_id, users.username;" | "${PSQL[@]}" -v username="$username")
if [[ -z $user_record ]]; then
  user_id=$(printf "%s\n" "INSERT INTO users(username) VALUES (:'username') RETURNING user_id;" | "${PSQL[@]}" -v username="$username")
  echo "Welcome, $username! It looks like this is your first time here."
else
  IFS='|' read -r username user_id games_played best_game <<< "$user_record"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"

while true; do
  if ! read -r guess; then
    exit 1
  fi

  if [[ ! $guess =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $guess == -* ]]; then
    guess_number=$((0 - 10#${guess#-}))
  else
    guess_number=$((10#$guess))
  fi
  ((number_of_guesses += 1))

  if ((guess_number < secret_number)); then
    echo "It's higher than that, guess again:"
  elif ((guess_number > secret_number)); then
    echo "It's lower than that, guess again:"
  else
    "${PSQL[@]}" -c "INSERT INTO games(user_id, number_guesses) VALUES ($user_id, $number_of_guesses);" >/dev/null
    echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
    break
  fi
done
