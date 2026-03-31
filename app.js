const currency = new Intl.NumberFormat('ar-SA', {
  style: 'currency',
  currency: 'SAR',
  maximumFractionDigits: 2,
});

const state = {
  transactions: JSON.parse(localStorage.getItem('transactions') || '[]'),
  bills: JSON.parse(localStorage.getItem('bills') || '[]'),
  goal: JSON.parse(localStorage.getItem('goal') || '{"name":"","target":0}'),
};

const transactionForm = document.getElementById('transactionForm');
const goalForm = document.getElementById('goalForm');
const billForm = document.getElementById('billForm');

const balanceValue = document.getElementById('balanceValue');
const incomeValue = document.getElementById('incomeValue');
const expenseValue = document.getElementById('expenseValue');

const goalTitle = document.getElementById('goalTitle');
const goalSaved = document.getElementById('goalSaved');
const goalTargetText = document.getElementById('goalTargetText');
const goalProgress = document.getElementById('goalProgress');

const transactionList = document.getElementById('transactionList');
const billList = document.getElementById('billList');

const today = new Date().toISOString().slice(0, 10);
document.getElementById('date').value = today;
document.getElementById('billDate').value = today;

transactionForm.addEventListener('submit', (event) => {
  event.preventDefault();

  const type = document.getElementById('type').value;
  const category = document.getElementById('category').value.trim();
  const amount = Number(document.getElementById('amount').value);
  const date = document.getElementById('date').value;

  if (!category || amount <= 0 || !date) return;

  state.transactions.unshift({ id: crypto.randomUUID(), type, category, amount, date });
  persist();
  render();
  transactionForm.reset();
  document.getElementById('type').value = 'income';
  document.getElementById('date').value = today;
});

goalForm.addEventListener('submit', (event) => {
  event.preventDefault();
  const name = document.getElementById('goalName').value.trim();
  const target = Number(document.getElementById('goalTarget').value);

  if (!name || target <= 0) return;

  state.goal = { name, target };
  persist();
  render();
  goalForm.reset();
});

billForm.addEventListener('submit', (event) => {
  event.preventDefault();
  const name = document.getElementById('billName').value.trim();
  const amount = Number(document.getElementById('billAmount').value);
  const dueDate = document.getElementById('billDate').value;

  if (!name || amount <= 0 || !dueDate) return;

  state.bills.push({ id: crypto.randomUUID(), name, amount, dueDate });
  state.bills.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
  persist();
  render();
  billForm.reset();
  document.getElementById('billDate').value = today;
});

function totals() {
  const income = state.transactions
    .filter((item) => item.type === 'income')
    .reduce((sum, item) => sum + item.amount, 0);

  const expense = state.transactions
    .filter((item) => item.type === 'expense')
    .reduce((sum, item) => sum + item.amount, 0);

  return { income, expense, balance: income - expense };
}

function render() {
  const { income, expense, balance } = totals();

  incomeValue.textContent = currency.format(income);
  expenseValue.textContent = currency.format(expense);
  balanceValue.textContent = currency.format(balance);

  renderTransactions();
  renderBills();
  renderGoal(balance);
}

function renderTransactions() {
  transactionList.innerHTML = '';
  if (!state.transactions.length) {
    transactionList.innerHTML = '<li>لا توجد عمليات حتى الآن.</li>';
    return;
  }

  state.transactions.forEach((item) => {
    const li = document.createElement('li');
    li.innerHTML = `
      <div>
        <strong>${item.category}</strong>
        <div class="meta">${item.date}</div>
      </div>
      <strong style="color:${item.type === 'income' ? '#00c3a5' : '#ff6b7d'}">
        ${item.type === 'income' ? '+' : '-'} ${currency.format(item.amount)}
      </strong>
    `;
    transactionList.appendChild(li);
  });
}

function renderBills() {
  billList.innerHTML = '';
  if (!state.bills.length) {
    billList.innerHTML = '<li>لا توجد فواتير مضافة.</li>';
    return;
  }

  state.bills.forEach((bill) => {
    const li = document.createElement('li');
    li.innerHTML = `
      <div>
        <strong>${bill.name}</strong>
        <div class="meta">استحقاق: ${bill.dueDate}</div>
      </div>
      <strong>${currency.format(bill.amount)}</strong>
    `;
    billList.appendChild(li);
  });
}

function renderGoal(balance) {
  const target = state.goal.target || 0;
  const safeBalance = balance > 0 ? balance : 0;
  const progress = target > 0 ? Math.min((safeBalance / target) * 100, 100) : 0;

  goalTitle.textContent = state.goal.name || 'لا يوجد هدف حالياً';
  goalSaved.textContent = currency.format(safeBalance);
  goalTargetText.textContent = currency.format(target);
  goalProgress.style.width = `${progress}%`;
}

function persist() {
  localStorage.setItem('transactions', JSON.stringify(state.transactions));
  localStorage.setItem('bills', JSON.stringify(state.bills));
  localStorage.setItem('goal', JSON.stringify(state.goal));
}

render();
