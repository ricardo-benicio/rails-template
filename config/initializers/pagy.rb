# frozen_string_literal: true

# Pagy configuration
# See https://ddnexus.github.io/pagy/

require "pagy/extras/overflow"
require "pagy/extras/metadata"

# Items per page
Pagy::DEFAULT[:items] = 25

# Default page param
Pagy::DEFAULT[:page_param] = :page

# Default items param
Pagy::DEFAULT[:items_param] = :per_page

# Overflow handling
Pagy::DEFAULT[:overflow] = :last_page

# Size of pagination links
Pagy::DEFAULT[:size] = 7
