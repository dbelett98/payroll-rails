# db/seeds.rb: Seeds test data for admin, staff, and clients (free open-source Rails rake task).
User.destroy_all  # Clears existing for fresh start (free).
Client.destroy_all  # Clear clients (free).

# Test Admin (president with full access).
admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'testpassword'
  user.password_confirmation = 'testpassword'
  user.role = 'ADMIN'
end

# Test Staff (worker with limited access).
staff = User.find_or_create_by!(email: 'staff@example.com') do |user|
  user.password = 'testpassword'
  user.password_confirmation = 'testpassword'
  user.role = 'STAFF'
end

# Test Clients for Admin.
Client.find_or_create_by!(name: 'Admin Test Client 1', bank_account: '123456789', user: admin)
Client.find_or_create_by!(name: 'Admin Test Client 2', bank_account: '987654321', user: admin)

# Test Clients for Staff.
Client.find_or_create_by!(name: 'Staff Test Client 1', bank_account: '112233445', user: staff)
Client.find_or_create_by!(name: 'Staff Test Client 2', bank_account: '554433221', user: staff)

puts 'Test data seeded for admin, staff, and clients'