module Returns
  module Fragments
    RETURN_ITEM = <<~QUERY
      fragment ReturnItem on Return {
        id
        status
        returnLineItems(first: 20) {
          edges {
            node {
              quantity
              fulfillmentLineItem {
                lineItem {
                  id
                }
              }
            }
          }
        }
      }
    QUERY
  end
end