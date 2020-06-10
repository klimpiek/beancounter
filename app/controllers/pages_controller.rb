require 'csv'

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:welcome, :guide]

  def beancheck
    path = Pathname.new(current_user.save_beancount)

    @errors = Rails.cache.fetch(["validation", current_user.cache_key, current_user.beancount_cached_at]) do
      %x(bean-check #{path} 2>&1)
    end
  end

  def beancount
    @entries = current_user.entries.order("date DESC")
  end

  def statistics
    if params[:date].present? && (@date = DateTime.parse(params[:date]))
    else
      @date = DateTime.current
    end

    month = @date.month
    year = @date.year

    if current_user.entries.empty?
      @current_month = ""
      @current_year = ""
    else
      month_expense = current_user.expenses.find_by(year: year, month: month)
      if month_expense.blank? || (month_expense.updated_at < current_user.entries.maximum(:updated_at))
        ExpensesJob.perform_now(current_user, year, month)
      end

      year_expense = current_user.expenses.find_by(year: year, month: nil)
      if year_expense.blank? || (year_expense.updated_at < current_user.entries.maximum(:updated_at))
        ExpensesJob.perform_now(current_user, year, nil)
      end

      @current_month = current_user.expenses.find_by(year: year, month: month).try(:details)
      @current_year = current_user.expenses.find_by(year: year, month: nil).try(:details)
    end
  end

  def guide
  end

  def welcome
  end
end
