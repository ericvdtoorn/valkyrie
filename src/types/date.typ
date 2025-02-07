#import "../base-type.typ": base-type, assert-base-type
#import "../context.typ": context

/// Valkyrie schema generator for integer- and floating-point numbers
///
/// - name (internal):
/// - default (integer, float, none): Default value to set if none is provided. *MUST* respect all other validation requirements.
/// - min (integer, none): If not none, the minimum value that satisfies the validation. The program is *ILL-FORMED* if `min` is greater than `max`.
/// - max (integer, none): If not none, the maximum value that satisfies the validation. The program is *ILL-FORMED* if `max` is less than `min`.
/// - custom (function, none): If not none, a function that, if itself returns none, will produce the error set by `custom-error`.
/// - custom-error (string, none): If set, the error produced upon failure of `custom`.
/// - transform (function): a mapping function called after validation.
/// - types (internal):
/// -> schema
#let date(
  name: "date",
  default: none,
  min: none,
  max: none,
  custom: none,
  custom-error: auto,
  transform: it=>it,
  types: (datetime),
) = {

  // Type safety
  assert( type(default) in (..types, type(none)),
    message: "Default of date must be of type datetime, or none (possibly narrowed)")
  assert( type(min) in (..types, type(none)), message: "Minimum value must be an datetime")
  assert( type(max) in (..types, type(none)), message: "Maximum value must be an datetime")

  assert( type(custom) in (function, type(none)), message: "Custom must be a function")
  assert( type(custom-error) in (str, type(auto)), message: "Custom-error must be a string")
  assert( type(transform) == function, message: "Transform must be a function that takes a single datetime and return a datetime")

  return (:..base-type(),
    name: name,
    default: default,
    min: min,
    max: max,
    custom: custom,
    custom-error: custom-error,
    transform: transform,
    types: types,

    validate: (self, it, ctx: context(), scope: ()) => {

      // TO DO: Coercion

      // Default value
      if ( it == none ){ it = self.default }

      // Assert type
      if not (self.assert-type)(self, it, ctx: ctx, scope: scope, types: types){
        return none
      }

      // Minimum value
      if ( self.min != none ) and (it < self.min ){
        return (self.fail-validation)( self, it, ctx: ctx, scope: scope,
          message: "Value less than specified minimum of " + str(self.min))
      }

      // Maximum value
      if ( self.max != none ) and (it > self.max ){
        return (self.fail-validation)( self, it, ctx: ctx, scope: scope,
          message: "Value greater than specified maximum of " + str(self.max))
      }

      // Custom
      if ( self.custom != none ) and ( not (self.custom)(it) ){
        let message = "Failed on custom check: " + repr(self.custom)
        if ( self.custom-error != auto ){ message = self.custom-error }
        return (self.fail-validation)(self, it, ctx: ctx, scope: scope, message: message)
      }

      return (self.transform)(it)
    }
  )
}

