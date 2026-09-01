const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres.osnhftjsormgodsabdbn:CSE327%40TradeLink@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres'
});
client.connect().then(() => {
  return client.query("ALTER TABLE public.order_chats DISABLE ROW LEVEL SECURITY; ALTER TABLE public.order_messages DISABLE ROW LEVEL SECURITY;");
}).then(res => {
  console.log('Success');
  client.end();
}).catch(err => {
  console.error(err);
  client.end();
});
