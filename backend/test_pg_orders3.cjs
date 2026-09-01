const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres.osnhftjsormgodsabdbn:CSE327%40TradeLink@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres'
});
client.connect().then(() => {
  return client.query("SELECT id, inventory_id, shop_owner_id, supplier_id, demand_id FROM orders WHERE id = '25bfc940-6d87-447e-93e3-c8eb7935eedd'");
}).then(res => {
  console.log(JSON.stringify(res.rows, null, 2));
  client.end();
}).catch(err => {
  console.error(err);
  client.end();
});
