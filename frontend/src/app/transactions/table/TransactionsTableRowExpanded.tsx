import React, { useState } from 'react';
import DatePicker from 'react-datepicker';
import 'react-datepicker/dist/react-datepicker.css';
import { ChevronDoubleUpIcon } from "@heroicons/react/24/outline";
import { Category, Transaction } from "../../lib/definitions";
import CategoryDropdown from "@/app/ui/shared/CategoryDropdown";
import { formatCurrency } from '@/app/lib/helpers';

interface TransactionTableRowExpandedProps {
  transaction: Transaction;
  categories: Category[];
  setExpandedRowTransactionId: React.Dispatch<React.SetStateAction<number | null>>;
  onUpdateTransactionDate: (transaction_id: number, newDate: string) => void;
  onUpdateTransactionSubcategory: (transaction_id: number, newSubcategoryName: string) => void;
};

export default function TransactionTableRowExpanded({
  transaction,
  categories,
  setExpandedRowTransactionId,
  onUpdateTransactionDate,
  onUpdateTransactionSubcategory
}: TransactionTableRowExpandedProps) {
  // Event handler for when date is selected:
  const handleDateSelect = (date: Date | null) => {
    if (date) {
      const newDate = `${date.getFullYear()}-${date.getMonth()+1}-${date.getDate()}`;
    onUpdateTransactionDate(transaction.id, newDate);
    }
  }

  return (<>
    {/* original row */}
    <tr
      key={transaction.id}
      className="bg-neutral-50 mb-2 \
      text-sm \
      last-of-type:border-none"
    >
      <td className="w-24 p-2 align-top whitespace-nowrap">
        <DatePicker
          className="w-full"
          selected={new Date(transaction.transaction_date)}
          isClearable={false}
          onChange={(date) => handleDateSelect(date)}
          fixedHeight
          popperPlacement="bottom-end"
        />
      </td>
      <td className="w-64 p-2 align-top whitespace-nowrap">
          <span>{transaction.description}</span>
      </td>
      <td className="w-48 p-2 absolute align-top whitespace-nowrap">
        <CategoryDropdown
          categories={categories}
          currentCategory={transaction.subcategory.name}
          onChange={
            (subcategoryName) => onUpdateTransactionSubcategory(
              transaction.id,
              subcategoryName
            )
          }
        />
      </td>
      <td className="w-24 p-2 align-top whitespace-nowrap">
        <span>{formatCurrency(transaction.amount)}</span>
      </td>
      <td>
        <div className="w-4"/>
      </td>
    </tr>
    {/* expanded row */}
    <tr className="bg-neutral-50">
      <td colSpan={5}>
        <hr/>
        <div className="flex justify-between w-full h-40">
          {/* Additional transaction content here */}
          <p className="flex-none content-start pl-2">Extra transaction data...</p>
          <div
            className="w-7 h-full whitespace-nowrap \
              order-last flex-none justify-self-end\
              flex justify-center items-center  \
              cursor-pointer \
              hover:bg-slate-100 hover:rounded-lg \
              hover:border hover:border-bg-slate-100"
            onClick={() => setExpandedRowTransactionId(null)}
          >
            <ChevronDoubleUpIcon className="w-4 h-4" />
          </div>
        </div>
        <hr/>
      </td>
    </tr>
  </>);
}