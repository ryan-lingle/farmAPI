class Asset < ApplicationRecord
  # Associations
  has_and_belongs_to_many :logs

  # Validations
  validates :name, presence: true
  validates :status, inclusion: { in: %w[active archived] }, allow_nil: true

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :archived, -> { where(status: "archived") }
  scope :locations, -> { where(is_location: true) }

  # Callbacks
  before_validation :set_defaults

  # Methods
  def archive!
    update!(status: "archived", archived_at: Time.current)
  end

  def active?
    status == "active"
  end

  def archived?
    status == "archived"
  end

  private

  def set_defaults
    self.status ||= "active"
    self.is_location ||= false
    self.is_fixed ||= false
  end
end
