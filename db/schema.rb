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

ActiveRecord::Schema[7.1].define(version: 2025_08_14_004018) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "bank_account"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "ssn"
    t.string "bank_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "hourly_rate"
    t.decimal "salary"
    t.bigint "client_id", null: false
    t.index ["client_id"], name: "index_employees_on_client_id"
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
    t.index ["client_id"], name: "index_payroll_runs_on_client_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
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
end
