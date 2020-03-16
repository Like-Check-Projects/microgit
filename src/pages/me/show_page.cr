class Me::ShowPage < MainLayout
  quick_def page_title, "Me"

  def content
    h1 "This is your profile"
    h3 "Email:  #{@current_user.email}"
    para "username:  #{@current_user.username}"
    helpful_tips
  end

  private def helpful_tips
    h3 "Next, you may want to:"
    ul do
      li { link_to_authentication_guides }
      li "Modify this page: src/pages/me/show_page.cr"
      li "Change where you go after sign in: src/actions/home/index.cr"
    end
  end

  private def link_to_authentication_guides
    link "Check out the authentication guides",
      to: "https://luckyframework.org/guides/authentication"
  end
end
