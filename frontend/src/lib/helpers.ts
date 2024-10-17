// Helper function to format amount as dollar value
export const formatCurrency = (amount: number) => {
  const formattedAmount = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(Math.abs(amount));

  return amount < 0 ? `-${formattedAmount}` : `${formattedAmount}`;
};

export const formatDate = (dateString: string) => {
  const [year, month, day] = dateString.split('-');
  return `${month}-${day}-${year}`;
};
