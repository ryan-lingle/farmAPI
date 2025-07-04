class Log < ApplicationRecord
  # Associations
  has_many :quantities, dependent: :destroy
  has_and_belongs_to_many :assets

  accepts_nested_attributes_for :quantities, allow_destroy: true

  # Validations
  validates :name, presence: true
  validates :status, inclusion: { in: %w[pending done] }, allow_nil: true
  validates :timestamp, presence: true

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :done, -> { where(status: "done") }
  scope :recent, -> { order(timestamp: :desc) }

  # Callbacks
  before_validation :set_defaults

  # Methods
  def complete!
    update!(status: "done")
  end

  def pending?
    status == "pending"
  end

  def done?
    status == "done"
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.timestamp ||= Time.current
  end
end
