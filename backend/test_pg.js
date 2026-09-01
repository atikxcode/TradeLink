const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres.osnhftjsormgodsabdbn:CSE327%40TradeLink@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres'
});
client.connect().then(() => {
  return client.query(
    ALTER TABLE public.order_chats DISABLE ROW LEVEL SECURITY;
    ALTER TABLE public.order_messages DISABLE ROW LEVEL SECURITY;
    CREATE POLICY "Allow public select on order_chats" ON public.order_chats FOR SELECT USING (true);
    CREATE POLICY "Allow insert on order_chats" ON public.order_chats FOR INSERT WITH CHECK (true);
    CREATE POLICY "Allow public select on order_messages" ON public.order_messages FOR SELECT USING (true);
    CREATE POLICY "Allow insert on order_messages" ON public.order_messages FOR INSERT WITH CHECK (true);
  );
}).then(res => {
  console.log('Success');
  client.end();
}).catch(err => {
  console.error(err);
  client.end();
});
