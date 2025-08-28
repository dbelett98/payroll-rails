# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_08_28_012943) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "bank_account"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ein"
    t.text "address"
    t.string "phone"
    t.string "email"
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "ssn"
    t.string "bank_account_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "hourly_rate"
    t.decimal "salary"
    t.bigint "client_id", null: false
    t.decimal "hours_worked"
    t.string "title"
    t.text "bank_routing_number"
    t.date "hire_date"
    t.string "employment_type", default: "W2"
    t.string "department"
    t.string "pay_frequency", default: "biweekly"
    t.string "status", default: "active"
    t.integer "federal_withholding_allowances", default: 0
    t.decimal "federal_additional_withholding", precision: 8, scale: 2, default: "0.0"
    t.integer "state_withholding_allowances", default: 0
    t.decimal "state_additional_withholding", precision: 8, scale: 2, default: "0.0"
    t.string "marital_status"
    t.text "address"
    t.string "phone"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "email"
    t.string "emergency_contact_relationship"
    t.index ["client_id"], name: "index_employees_on_client_id"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["employment_type"], name: "index_employees_on_employment_type"
    t.index ["pay_frequency"], name: "index_employees_on_pay_frequency"
    t.index ["status"], name: "index_employees_on_status"
  end

  create_table "payroll_entries", force: :cascade do |t|
    t.decimal "hours_worked"
    t.decimal "gross_pay"
    t.decimal "deductions"
    t.decimal "net_pay"
    t.bigint "employee_id", null: false
    t.bigint "payroll_run_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_payroll_entries_on_employee_id"
    t.index ["payroll_run_id"], name: "index_payroll_entries_on_payroll_run_id"
  end

  create_table "payroll_runs", force: :cascade do |t|
    t.datetime "run_date"
    t.decimal "total_gross"
    t.decimal "total_net"
    t.decimal "taxes_withheld"
    t.string "status"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "employee_id"
    t.index ["client_id"], name: "index_payroll_runs_on_client_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "clients", "users"
  add_foreign_key "employees", "clients"
  add_foreign_key "payroll_entries", "employees"
  add_foreign_key "payroll_entries", "payroll_runs"
  add_foreign_key "payroll_runs", "clients"
  add_foreign_key "payroll_runs", "employees"
end
