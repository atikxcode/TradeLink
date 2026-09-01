const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres.osnhftjsormgodsabdbn:CSE327%40TradeLink@aws-0-ap-northeast-1.pooler.supabase.com:6543/postgres'
});
client.connect().then(() => {
  return client.query("SELECT id, product_name, quantity, total_amount, status FROM orders WHERE status = 'searching_for_rider'");
}).then(res => {
  console.log(JSON.stringify(res.rows, null, 2));
  client.end();
}).catch(err => {
  console.error(err);
  client.end();
});
