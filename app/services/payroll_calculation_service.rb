# app/services/payroll_calculation_service.rb
class PayrollCalculationService
  attr_reader :employee, :pay_period_hours, :calculation_date

  def initialize(employee, pay_period_hours = nil, calculation_date = Date.current)
    @employee = employee
    @pay_period_hours = pay_period_hours || employee.hours_worked || 0
    @calculation_date = calculation_date
  end

  def calculate
    {
      employee_info: employee_summary,
      gross_pay: calculate_gross_pay,
      overtime_info: calculate_overtime,
      federal_taxes: calculate_federal_taxes_placeholder,
      state_taxes: calculate_state_taxes_placeholder,
      deductions: calculate_deductions_placeholder,
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

  def calculate_gross_pay
    case employee.employment_type
    when 'W2'
      if employee.salary && employee.salary > 0
        calculate_salary_gross_pay
      else
        calculate_hourly_gross_pay
      end
    when '1099'
      calculate_hourly_gross_pay
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
      employee.salary / 26.0
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
    return @pay_period_hours if @pay_period_hours

    total_hours = employee.hours_worked || 0
    
    case employee.pay_frequency
    when 'weekly'
      total_hours / 4.0
    when 'biweekly'
      total_hours / 2.0
    when 'semimonthly'
      total_hours / 2.0
    when 'monthly'
      total_hours
    else
      total_hours / 2.0
    end
  end

  def regular_hours_limit_for_period
    case employee.pay_frequency
    when 'weekly'
      40.0
    when 'biweekly'
      80.0
    when 'semimonthly'
      86.67
    when 'monthly'
      173.33
    else
      80.0
    end
  end

  def calculate_federal_taxes_placeholder
    gross_pay = calculate_gross_pay
    
    {
      withholding: calculate_federal_withholding(gross_pay),
      social_security: calculate_social_security(gross_pay),
      medicare: calculate_medicare(gross_pay)
    }
  end

  def calculate_federal_withholding(gross_pay)
    annual_gross = gross_pay * pay_periods_per_year
    
    standard_deduction = case employee.marital_status&.downcase
                         when 'married', 'married filing jointly'
                           29700
                         when 'married filing separately'
                           14850
                         when 'head of household'
                           22200
                         else
                           14850
                         end
    
    allowance_amount = (employee.federal_withholding_allowances || 0) * 4850
    taxable_income = [annual_gross - standard_deduction - allowance_amount, 0].max
    
    annual_tax = if taxable_income <= 11600
                   taxable_income * 0.10
                 elsif taxable_income <= 47150
                   1160 + (taxable_income - 11600) * 0.12
                 elsif taxable_income <= 100525
                   5426 + (taxable_income - 47150) * 0.22
                 elsif taxable_income <= 191950
                   17168.50 + (taxable_income - 100525) * 0.24
                 elsif taxable_income <= 243725
                   39110.50 + (taxable_income - 191950) * 0.32
                 else
                   55678.50 + (taxable_income - 243725) * 0.37
                 end
    
    period_withholding = annual_tax / pay_periods_per_year
    additional = employee.federal_additional_withholding || 0
    
    [period_withholding + additional, 0].max.round(2)
  end

  def calculate_social_security(gross_pay)
    ss_rate = 0.062
    ss_wage_base = 176100
    
    annual_gross = gross_pay * pay_periods_per_year
    if annual_gross <= ss_wage_base
      (gross_pay * ss_rate).round(2)
    else
      capped_amount = [gross_pay, ss_wage_base / pay_periods_per_year].min
      (capped_amount * ss_rate).round(2)
    end
  end

  def calculate_medicare(gross_pay)
    medicare_rate = 0.0145
    additional_medicare_threshold = 200000
    
    base_medicare = (gross_pay * medicare_rate).round(2)
    
    annual_gross = gross_pay * pay_periods_per_year
    if annual_gross > additional_medicare_threshold
      additional_rate = 0.009
      additional_medicare = (gross_pay * additional_rate).round(2)
      base_medicare + additional_medicare
    else
      base_medicare
    end
  end

  def pay_periods_per_year
    case employee.pay_frequency
    when 'weekly'
      52
    when 'biweekly'
      26
    when 'semimonthly'
      24
    when 'monthly'
      12
    else
      26
    end
  end

  def calculate_state_taxes_placeholder
    gross_pay = calculate_gross_pay
    state = get_employee_state
    
    case state.upcase
    when 'IL', 'ILLINOIS'
      calculate_illinois_state_taxes(gross_pay)
    when 'FL', 'FLORIDA'
      calculate_florida_state_taxes(gross_pay)
    when 'CA', 'CALIFORNIA'
      calculate_california_state_taxes(gross_pay)
    when 'NY', 'NEW YORK'
      calculate_newyork_state_taxes(gross_pay)
    when 'TX', 'TEXAS'
      calculate_texas_state_taxes(gross_pay)
    else
      { withholding: 0.0, sdi: 0.0, sui: 0.0 }
    end
  end

  def get_employee_state
    if employee.address.present?
      extracted_state = extract_state_from_address(employee.address)
      return extracted_state if extracted_state
    end
    
    if employee.client&.address.present?
      extracted_state = extract_state_from_address(employee.client.address)
      return extracted_state if extracted_state
    end
    
    'UNKNOWN'
  end

  def extract_state_from_address(address)
    state_codes = %w[AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY]
    
    state_codes.each do |code|
      return code if address.upcase.include?(" #{code} ") || address.upcase.end_with?(" #{code}")
    end
    
    return 'IL' if address.upcase.include?('ILLINOIS')
    return 'FL' if address.upcase.include?('FLORIDA')
    return 'CA' if address.upcase.include?('CALIFORNIA')
    return 'NY' if address.upcase.include?('NEW YORK')
    return 'TX' if address.upcase.include?('TEXAS')
    
    nil
  end

  def calculate_illinois_state_taxes(gross_pay)
    il_rate = 0.0495
    withholding = gross_pay * il_rate
    additional = employee.state_additional_withholding || 0
    
    { 
      withholding: (withholding + additional).round(2), 
      sdi: 0.0, 
      sui: 0.0
    }
  end

  def calculate_florida_state_taxes(gross_pay)
    { 
      withholding: 0.0, 
      sdi: 0.0, 
      sui: 0.0
    }
  end

  def calculate_california_state_taxes(gross_pay)
    ca_rate = 0.04
    withholding = gross_pay * ca_rate
    sdi_rate = 0.009
    
    { 
      withholding: withholding.round(2), 
      sdi: (gross_pay * sdi_rate).round(2), 
      sui: 0.0
    }
  end

  def calculate_newyork_state_taxes(gross_pay)
    ny_rate = 0.065
    withholding = gross_pay * ny_rate
    
    { 
      withholding: withholding.round(2), 
      sdi: 0.0, 
      sui: 0.0
    }
  end

  def calculate_texas_state_taxes(gross_pay)
    { 
      withholding: 0.0, 
      sdi: 0.0, 
      sui: 0.0
    }
  end

  def calculate_deductions_placeholder
    gross_pay = calculate_gross_pay
    
    {
      health_insurance: calculate_health_insurance_deduction(gross_pay),
      retirement_401k: calculate_401k_deduction(gross_pay),
      other: calculate_other_deductions(gross_pay)
    }
  end

  def calculate_health_insurance_deduction(gross_pay)
    case employee.pay_frequency
    when 'weekly'
      25.00
    when 'biweekly'
      50.00
    when 'semimonthly'
      50.00
    when 'monthly'
      100.00
    else
      50.00
    end
  end

  def calculate_401k_deduction(gross_pay)
    contribution_rate = 0.03
    (gross_pay * contribution_rate).round(2)
  end

  def calculate_other_deductions(gross_pay)
    0.00
  end

  def calculate_net_pay
    gross = calculate_gross_pay
    fed_taxes = calculate_federal_taxes_placeholder.values.sum
    state_taxes = calculate_state_taxes_placeholder.values.sum
    deductions = calculate_deductions_placeholder.values.sum
    
    net = gross - fed_taxes - state_taxes - deductions
    [net, 0].max.round(2)
  end
end