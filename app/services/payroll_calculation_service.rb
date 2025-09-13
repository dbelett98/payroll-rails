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

  # We'll implement these methods in subsequent parts
  def calculate_gross_pay
    # Part 2: Gross pay calculation
    0.0
  end

  def calculate_overtime
    # Part 2: Overtime calculation
    { regular_hours: 0, overtime_hours: 0, overtime_rate: 0 }
  end

  def calculate_federal_taxes
    # Part 3: Federal tax calculation
    { withholding: 0.0, social_security: 0.0, medicare: 0.0 }
  end

  def calculate_state_taxes
    # Part 4: State tax calculation
    { withholding: 0.0, sdi: 0.0, sui: 0.0 }
  end

  def calculate_deductions
    # Part 5: Deductions calculation
    { health_insurance: 0.0, retirement_401k: 0.0, other: 0.0 }
  end

  def calculate_net_pay
    gross = calculate_gross_pay
    fed_taxes = calculate_federal_taxes.values.sum
    state_taxes = calculate_state_taxes.values.sum
    deductions = calculate_deductions.values.sum
    
    gross - fed_taxes - state_taxes - deductions
  end
end