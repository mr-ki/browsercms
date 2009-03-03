# This controller handles the login/logout function of the site.  
class Cms::SessionsController < Cms::BaseController
  
  skip_before_filter :login_required
  layout "cms/login"
  def login
    logger.info "session[:return_to] => #{session[:return_to]}"
    logger.info "params[:success_url] => #{params[:success_url]}"
    if request.post?
      logout_keeping_session!
      user = User.authenticate(params[:login], params[:password])
      if user
        # Protects against session fixation attacks, causes request forgery
        # protection if user resubmits an earlier form using back
        # button. Uncomment if you understand the tradeoffs.
        # reset_session
        self.current_user = user
        new_cookie_flag = (params[:remember_me] == "1")
        handle_remember_cookie! new_cookie_flag
        flash[:notice] = "Logged in successfully"
        if params[:success_url] # Coming from login portlet
          redirect_to(session[:return_to] || params[:success_url] || "/")          
          session[:return_to] = nil
        else
          redirect_back_or_default(cms_home_url)
        end
      else
        note_failed_signin
        @login       = params[:login]
        @remember_me = params[:remember_me]
        flash[:login_error] = "Log in failed"  
        if params[:success_url] # Coming from login portlet
          if params[:success_url].blank?
            success_url = session[:return_to] || "/"
          else
            success_url = params[:success_url]
          end
          flash[:login] = params[:login]
          flash[:remember_me] = params[:remember_me]
          flash[:success_url] = success_url
          redirect_to request.referrer
        end  
      end
    end
  end

  def logout
    logout_killing_session!
    cookies.delete :openSectionNodes
    flash[:notice] = "You have been logged out."
    redirect_back_or_default("/")
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Couldn't log you in as '#{params[:login]}'"
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
  
end
