# Pages CMS

[Pages CMS](https://pagescms.org) is an open source CMS for GitHub repositories. It is especially well suited for static sites and content-driven apps built with tools like Jekyll, Hugo, Next.js, Astro, VuePress, and similar stacks.

You can use the hosted version directly at [app.pagescms.org](https://app.pagescms.org), or run your own local development copy from this repository.

[![Screenshot of the Pages CMS editor](https://pagescms.org/media/screenshot.png)](https://demo.pagescms.org)

*[Watch the demo ▶](https://demo.pagescms.org)*

## Documentation

Full documentation lives at [pagescms.org/docs](https://pagescms.org/docs).

Useful starting points:

- [Install locally](https://pagescms.org/docs/guides/installing/)
- [Create the GitHub App](https://pagescms.org/docs/guides/installing/github-app/)
- [Environment variables](https://pagescms.org/docs/development/environment-variables/)
- [Upgrading to 2.x](https://pagescms.org/docs/guides/upgrading-to-2/)

## Use online

The easiest way to get started is the hosted version at [app.pagescms.org](https://app.pagescms.org).

Use that if you want to:

- try Pages CMS immediately,
- edit content without running anything locally,
- stay on the latest hosted version.

## Self-hosting with Docker

A production Dockerfile and Compose setup are included. The image uses the Next.js standalone output and runs as a non-root user. Pending database migrations run automatically when the container starts.

### Quick start

1. Create the environment file:

```bash
cp .env.docker.example .env
```

2. Set at least `BASE_URL`, `BETTER_AUTH_SECRET`, `CRYPTO_KEY`, and `POSTGRES_PASSWORD` in `.env`. Generate the app secrets with:

```bash
openssl rand -base64 32
```

Use a URL-safe value for `POSTGRES_PASSWORD`, since it becomes part of `DATABASE_URL`:

```bash
openssl rand -hex 32
```

3. Create your GitHub App and add its credentials to `.env` with the helper:

```bash
npm run setup:github-app -- --base-url http://localhost:3000 --env .env
```

`BASE_URL` must match the URL used by the GitHub App callback, setup, and webhook URLs. See [Create the GitHub App](https://pagescms.org/docs/guides/installing/github-app/) if you prefer to configure it manually.

4. Build and start the app and database:

```bash
docker compose up -d --build
```

The app is available at `http://localhost:3000` by default. Change `APP_PORT` in `.env` to expose a different host port.

For production, put the app behind an HTTPS reverse proxy (Caddy, Nginx, or your platform's load balancer) and set `BASE_URL` to the public URL.

Useful commands:

```bash
docker compose logs -f app    # follow application logs
docker compose down           # stop the containers
docker compose down -v        # stop and delete the database volume
```

### Published images

The `Build and publish container` GitHub Actions workflow publishes an image to GitHub Container Registry on pushes to `main` and `v*` tags:

```bash
docker pull ghcr.io/<owner>/pagescms:latest
```

Replace `<owner>` with the GitHub account or organization that owns the repository. Packages are private by default; make the package public in its GitHub package settings to allow anonymous pulls. For private packages, authenticate with `docker login ghcr.io` first.

### Migrations

The app applies pending migrations before starting. Set `RUN_MIGRATIONS=false` if migrations are handled by a separate deployment job, then run them manually with:

```bash
docker compose run --rm -e RUN_MIGRATIONS=false app node scripts/migrate.mjs
```

Migrations are serialized with a PostgreSQL advisory lock, so starting multiple app replicas at the same time is safe.

### Using an external database

The app image only needs `DATABASE_URL`; it does not require the bundled `db` service. Use a Compose override to point the app at your PostgreSQL instance:

```yaml
# compose.override.yml
services:
  app:
    environment:
      DATABASE_URL: postgresql://user:password@your-db-host:5432/pagescms
```

Then build the image, run migrations, and start only the app:

```bash
docker compose build app
docker compose run --rm --no-deps -e RUN_MIGRATIONS=false app node scripts/migrate.mjs
docker compose up -d --no-deps app
```

You can also run the image directly with your own orchestrator by setting `DATABASE_URL` and the other required environment variables.

## Local development

### What you need

- PostgreSQL
- a GitHub App
- a local `.env.local`
- the Pages CMS repo checked out locally

### Quick start

1. Clone the repository:

```bash
git clone https://github.com/pagescms/pagescms.git
cd pagescms
```

2. Start PostgreSQL locally:

```bash
docker run --name pagescms-db -e POSTGRES_USER=pagescms -e POSTGRES_PASSWORD=pagescms -e POSTGRES_DB=pagescms -p 5432:5432 -d postgres:16
```

3. Install dependencies:

```bash
npm install
```

4. Create `.env.local` with at least:

```bash
DATABASE_URL=postgresql://pagescms:pagescms@localhost:5432/pagescms
BETTER_AUTH_SECRET=your-random-secret
CRYPTO_KEY=your-random-secret
```

Optional but useful:

```bash
BASE_URL=https://cms.example.com
ADMIN_EMAILS=admin@example.com
```

Notes:

- In production, `BASE_URL` should be the single canonical URL for the app.
- Do not mix a custom domain and a `*.netlify.app` URL for the same install.
- `ADMIN_EMAILS` is a comma-separated allowlist for access to the admin panel.

Generate secrets with:

```bash
openssl rand -base64 32
```

5. Create your GitHub App with the helper:

```bash
npm run setup:github-app -- --base-url http://localhost:3000
```

Useful options:

- `--owner-type personal|org`
- `--org <slug>`
- `--app-name "Pages CMS (local)"`
- `--env .env.local`
- `--no-open`

6. Run database migrations:

```bash
npm run db:migrate
```

If cache state is known stale or corrupted, clear it with:

```bash
npm run db:clear-cache
```

7. Start the app:

```bash
npm run dev
```

If you need GitHub webhooks to reach your local app, use a public tunnel URL as the helper `--base-url`.

For more detail, see:

- [Install locally](https://pagescms.org/docs/guides/installing/)
- [Create the GitHub App](https://pagescms.org/docs/guides/installing/github-app/)
- [Environment variables](https://pagescms.org/docs/development/environment-variables/)
- [Caching](https://pagescms.org/docs/development/caching/)

## Support the project

- [Contribute code](https://github.com/pagescms/pagescms/pulls)
- [Report issues](https://github.com/pagescms/pagescms/issues)
- [Sponsor me](https://github.com/sponsors/hunvreus)
- [Star the project on GitHub](https://github.com/pagescms/pagescms)
- [Join the Discord chat](https://pagescms.org/chat)

## License

Everything in this repo is released under the [MIT License](LICENSE).
