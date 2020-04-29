# Crudify
Crudify enables the creation of Dynamic CRUD actions. All CRUD actions are handled by this gem. This also provides Index powered by ransack.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'crudify', github: 'sammieValsangkar/crudify'
```

And then execute:
```bash
$ bundle
```


## Usage

Add in your config/routes.rb

```ruby
namespace :admin do
  resources :your_resource_name, controller: '/admin/resource'
end
```
And here you go.

It will create form according to datatypes and associations declared in model.
e.g.
1. If you declare belongs_to assocotation in your model.
It will generate dropdown to select the value. also provides dropdown to filter at index page.

2. For boolean attributes It will generate Radio button in form

3. It will add client side validation if validation declared in model.


### Note:
  1. You need Bootstrap 3 for to get better UI. soon we will add support for Bootstrap 4.
  
  2. All resources must be in admin namespace. we have not added any authentication for an admin. You can write your own             AdminController.
  
## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
