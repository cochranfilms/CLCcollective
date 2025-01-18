def index
  @projects = Project.joins(:invoice)
                    .where(invoices: { user_id: current_user.id })
                    .distinct
                    .order(created_at: :desc)
end 