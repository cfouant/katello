object false

extends "katello/api/v2/common/metadata"

child @collection[:results] => :results do
  extends 'katello/api/v2/ostree_branches/show'
  node :comparison do |result|
    result.comparison
  end
end
