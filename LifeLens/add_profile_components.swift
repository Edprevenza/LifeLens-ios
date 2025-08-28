// Missing components for EnhancedProfileView

struct EnhancedProfileHeaderCard: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                
            .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(authService.currentUser?.firstName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(authService.currentUser?.email ?? "")
                    .font(.caption)
                    
            .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmergencyContactsSection: View {
    @Binding var contacts: [EmergencyContact]
    @Binding var showingAddContact: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddContact = true }) {
                    Image(systemName: "plus.circle.fill")
                        
            .foregroundColor(.blue)
                }
            }
            
            ForEach(contacts, id: \.phone) { contact in
                HStack {
                    VStack(alignment: .leading) {
                        Text(contact.name)
                            .font(.subheadline)
                        Text(contact.relationship)
                            .font(.caption)
                            
            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(contact.phone)
                        .font(.caption)
                        
            .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnhancedProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    
            .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    
            .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    
            .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}