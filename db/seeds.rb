# db/seeds.rb: Seeds test data for admin, staff, clients, and employees (free open-source Rails rake task).
User.destroy_all  # Clears existing for fresh start (free).
Client.destroy_all

# Test Admin
admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  puts "Setting password for #{user.email}"
  user.password = 'testpassword'
  user.password_confirmation = 'testpassword'
  user.role = 'ADMIN'
end

# Test Staff
staff = User.find_or_create_by!(email: 'staff@example.com') do |user|
  puts "Setting password for #{user.email}"
  user.password = 'testpassword'
  user.password_confirmation = 'testpassword'
  user.role = 'STAFF'
end

# Test Clients for Admin
c1 = Client.find_or_create_by!(name: 'Admin Test Client 1', bank_account: '123456789', user: admin)
c2 = Client.find_or_create_by!(name: 'Admin Test Client 2', bank_account: '987654321', user: admin)

# Test Employees for Admin Clients
Employee.find_or_create_by!(name: 'Employee 1', hours_worked: 160, salary: 50000, client: c1)
Employee.find_or_create_by!(name: 'Employee 2', hours_worked: 120, salary: 60000, client: c2)

# Test Clients for Staff
c3 = Client.find_or_create_by!(name: 'Staff Test Client 1', bank_account: '112233445', user: staff)
c4 = Client.find_or_create_by!(name: 'Staff Test Client 2', bank_account: '554433221', user: staff)

# Test Employees for Staff Clients
Employee.find_or_create_by!(name: 'Employee 3', hours_worked: 140, salary: 45000, client: c3)
Employee.find_or_create_by!(name: 'Employee 4', hours_worked: 180, salary: 55000, client: c4)

puts 'Test data seeded for admin, staff, clients, and employees'