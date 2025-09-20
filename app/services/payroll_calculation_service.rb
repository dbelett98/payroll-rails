# app/services/payroll_calculation_service.rb
class PayrollCalculationService
  attr_reader :employee, :pay_period_hours, :calculation_date

  def initialize(employee, pay_period_hours = nil, calculation_date = Date.current)
    @employee = employee
    @pay_period_hours = pay_period_hours || employee.hours_worked || 0
    @calculation_date = calculation_date
  end

  # Main calculation method that returns all payroll components
  def calculate
    {
      employee_info: employee_summary,
      gross_pay: calculate_gross_pay,
      overtime_info: calculate_overtime,
      federal_taxes: calculate_federal_taxes,
      state_taxes: calculate_state_taxes,
      deductions: calculate_deductions,
      net_pay: calculate_net_pay
    }
  end

  private

  def employee_summary
    {
      name: employee.name,
      id: employee.id,
      employment_type: employee.employment_type,
      pay_frequency: employee.pay_frequency,
      marital_status: employee.marital_status
    }
  end

private

  def employee_summary
    {
      name: employee.name,
      id: employee.id,
      employment_type: employee.employment_type,
      pay_frequency: employee.pay_frequency,
      marital_status: employee.marital_status
    }
  end

  def calculate_gross_pay
    case employee.employment_type
    when 'W2'
      if employee.salary && employee.salary > 0
        calculate_salary_gross_pay
      else
        calculate_hourly_gross_pay
      end
    when '1099'
      calculate_hourly_gross_pay # 1099 workers are typically hourly
    else
      0.0
    end
  end

  def calculate_salary_gross_pay
    return 0.0 unless employee.salary

    case employee.pay_frequency
    when 'weekly'
      employee.salary / 52.0
    when 'biweekly'
      employee.salary / 26.0
    when 'semimonthly'
      employee.salary / 24.0
    when 'monthly'
      employee.salary / 12.0
    else
      employee.salary / 26.0 # default to biweekly
    end
  end

  def calculate_hourly_gross_pay
    overtime_info = calculate_overtime
    regular_pay = overtime_info[:regular_hours] * (employee.hourly_rate || 0)
    overtime_pay = overtime_info[:overtime_hours] * overtime_info[:overtime_rate]
    regular_pay + overtime_pay
  end

  def calculate_overtime
    return { regular_hours: 0, overtime_hours: 0, overtime_rate: 0 } unless employee.hourly_rate

    # Convert total hours to pay period hours
    pay_period_hours = hours_for_pay_period
    regular_hours_limit = regular_hours_limit_for_period

    if pay_period_hours <= regular_hours_limit
      {
        regular_hours: pay_period_hours,
        overtime_hours: 0,
        overtime_rate: employee.hourly_rate * 1.5
      }
    else
      {
        regular_hours: regular_hours_limit,
        overtime_hours: pay_period_hours - regular_hours_limit,
        overtime_rate: employee.hourly_rate * 1.5
      }
    end
  end

  def hours_for_pay_period
    # If specific pay period hours provided, use those
    return @pay_period_hours if @pay_period_hours

    # Otherwise convert from stored hours_worked based on pay frequency
    total_hours = employee.hours_worked || 0
    
    case employee.pay_frequency
    when 'weekly'
      total_hours / 4.0  # Assuming monthly storage
    when 'biweekly'
      total_hours / 2.0  # Assuming monthly storage
    when 'semimonthly'
      total_hours / 2.0
    when 'monthly'
      total_hours
    else
      total_hours / 2.0  # default to biweekly
    end
  end

  def regular_hours_limit_for_period
    case employee.pay_frequency
    when 'weekly'
      40.0
    when 'biweekly'
      80.0
    when 'semimonthly'
      86.67  # (40 * 52) / 24
    when 'monthly'
      173.33 # (40 * 52) / 12
    else
      80.0  # default to biweekly
    end
  end

  def calculate_net_pay
    gross = calculate_gross_pay
    fed_taxes = calculate_federal_taxes.values.sum
    state_taxes = calculate_state_taxes.values.sum
    deductions = calculate_deductions.values.sum
    
    gross - fed_taxes - state_taxes - deductions
  end
end