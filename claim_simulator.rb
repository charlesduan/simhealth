class ClaimSimulator

  def initialize(data)
    @name = data['name']
    @count = data['count']
    @claims = data['claims'].map { |cl_data|
      {
        :count => cl_data['count'],
        :category => cl_data['category'],
        :amount => cl_data['amount'],
      }
    }
  end
