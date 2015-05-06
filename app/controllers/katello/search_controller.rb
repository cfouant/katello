module Katello
  class SearchController < Katello::ApplicationController
    include SearchHelper

    def rules
      pass = lambda { true }
      {
        :show => pass,
        :create_favorite => pass,
        :destroy_favorite => pass
      }
    end

    def show
      # retrieve the search history and favorites for the user...
      # only return histories that are associated with the page the request is received on...
      path = retrieve_path

      @search_histories = current_user.search_histories.where("path LIKE ?", "%#{path}%").order("updated_at desc")
      @search_favorites = current_user.search_favorites.where("path LIKE ?", "%#{path}%").order("params asc")

      render :partial => "katello/common/search"

      # clean up the histories... we will only store the last N entries in the
      # search history, so delete any past N
      if @search_histories.length > max_search_history
        (max_search_history..@search_histories.length - 1).each do |i|
          @search_histories[i].delete unless @search_histories[i].nil?
        end
      end
    end

    def create_favorite
      # save in the user's search favorites
      unless params[:favorite].nil? || params[:favorite].blank?
        search_string = String.new(params[:favorite])
        path = retrieve_path

        # is the search string valid?  if not, don't save it...
        if valid? path, search_string
          favorites = current_user.search_favorites.where(:path => path, :params => params[:favorite])
          if favorites.nil? || favorites.empty?
            # user doesn't have this favorite stored, so save it
            current_user.search_favorites.create!(:path => path, :params => params[:favorite])
          end
        end
      end

      # return the search details after adding a new favorite
      show
    end

    def destroy_favorite
      current_user.search_favorites.destroy(params[:id])

      # return the search details after removing the favorite
      show
    end

    private

    def retrieve_path
      # retrieve the 'path' from the referrer (e.g. /katello/organizations), leaving out info such as
      # protocol, fqdn and port
      URI(request.env['HTTP_REFERER']).path
    end

    def valid?(_path, _query)
      # the path may contain a service prefix (e.g. /katello).  if it does, remove it from the path when
      # checking for path validity.  This is required since the routes do not know of this prefix.
      #path = path.split(Katello.config.prefix_url).last
      #path_details = Rails.application.routes.recognize_path(path)

      #eval(path_details[:controller].singularize.camelize).readable(current_organization).complete_for(query,
      #  {:organization_id => current_organization})

      return true
    end
  end
end
