/** @type {import('next').NextConfig} */
// Docker builds set NEXT_OUTPUT=standalone. Keeping it opt-in lets regular
// `npm run build` + `npm run start` deployments continue to work as before.
const nextConfig =
  process.env.NEXT_OUTPUT === "standalone" ? { output: "standalone" } : {};

export default nextConfig;
