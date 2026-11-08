# Company

A Torn userscript for company directors. It shows how the company is doing over time and gives advice to make more money.

## How it works

- The director signs in with a Limited Torn API key. Other keys, and players who are not a director, are rejected.
- The TornManager server stores the key encrypted and reads the company every evening at 18:30 TCT.
- The script only talks to `tornmanager.com`. It never calls the Torn API itself.
- Every Torn call made with the key carries `comment=tmcompany`.
- A TornManager subscription is required.

## Screens

- **Overview**: income, profit, customers, wages, staff, funds, rank against companies of the same type and stars, and advice.
- **Charts**: daily history of income, income per employee against the median and top 10%, customers, wages, funds, popularity, efficiency, environment and effectiveness.
- **Staff**: staff per position, and every employee with flags, effectiveness and stats against the position requirements.
- **Stock**: prices, stock and days of stock left.
- **News**: company news.

## Development

- `npm run dev`: build on change, pointed at `http://localhost:3000`.
- `npm run build`: lint and build to `dist/`.
- `npm run release`: build and copy to `userscript/tm-company.user.js`, which is the install and update link.

The admin page is at `/admin/company`.
