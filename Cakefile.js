(function() {
  var CoffeeKup, CoffeeScript, LESS, ccss, ccss_shortcuts, exec, fs, houce, less_options, standard_exec_func, task_name, templ_helpers;

  task_name = process.argv[2];

  if (task_name !== 'build_docs' && task_name !== 'docs_to_github') {
    require('sugar');
    Object.extend();
    require('./common/common_utils');
    less_options = {
      paths: ['./client', './client/styles']
    };
    LESS = require('less');
    CoffeeScript = require('coffee-script');
    CoffeeKup = require('coffeekup');
    ccss = require('ccss');
    templ_helpers = require('./client/styles/templ_helpers.s.coffee');
    houce = require("./server/houce.coffee");
  }

  fs = require('fs');

  exec = require('child_process').exec;

  standard_exec_func = function(err, stdout, stderr) {
    if (err) throw err;
    return console.log(stdout + stderr);
  };

  ccss_shortcuts = function(obj) {
    var del_old, key, val, _results;
    _results = [];
    for (key in obj) {
      val = obj[key];
      if (typeof val === 'object') ccss_shortcuts(val);
      del_old = key.slice(0, 2) === 'i_' ? obj['#' + key.slice(2)] = val : key.slice(0, 2) === 'c_' ? obj['.' + key.slice(2)] = val : false;
      if (del_old) {
        _results.push(delete obj[key]);
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  task('build_client', function() {
    var CSS, JS, app_file_path, ccss_css, ccss_obj, cu_str, file_extension, file_name, file_path, file_str, files, files_first, files_last, fof_path, full_templ_str, ind, read_folder, stringify, templ_str, templates, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
    log("Starting to build client files...");
    files = [];
    files_first = [];
    files_last = [];
    ind = 0;
    read_folder = function(path) {
      var file_or_folder, file_parts, fof_path, fof_stat, folder_contents, order, order_or_skip, _i, _len, _results;
      ind += 1;
      folder_contents = fs.readdirSync(path);
      _results = [];
      for (_i = 0, _len = folder_contents.length; _i < _len; _i++) {
        file_or_folder = folder_contents[_i];
        fof_path = path + '/' + file_or_folder;
        fof_stat = fs.statSync(fof_path);
        if (fof_stat.isDirectory()) {
          _results.push(read_folder(fof_path));
        } else {
          file_parts = file_or_folder.split('.');
          switch (file_parts.length) {
            case 2:
              _results.push(files.push(fof_path));
              break;
            case 3:
              order_or_skip = file_parts[1];
              if (order_or_skip.parsesToNumber()) {
                order = order_or_skip.toNumber();
                if (order < 0) {
                  _results.push(files_last[order.abs()] = fof_path);
                } else {
                  _results.push(files_first[order] = fof_path);
                }
              } else if (order_or_skip.toLowerCase() === 's') {
                _results.push(null);
              } else {
                throw "Unknown special type for: " + file_or_folder;
              }
              break;
            default:
              throw "Unknown file format: " + file_or_folder;
          }
        }
      }
      return _results;
    };
    read_folder(__dirname + '/client');
    _ref = files_first.compact().reverse();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      fof_path = _ref[_i];
      files.unshift(fof_path);
    }
    _ref2 = files_last.compact().reverse();
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      fof_path = _ref2[_j];
      files.push(fof_path);
    }
    templates = {};
    JS = "";
    CSS = "";
    ccss_css = "";
    JS += "\n\n\n/* --- COMMON_UTILS.COFFEE --- */\n\n";
    cu_str = fs.readFileSync(__dirname + "/common/common_utils.coffee").toString();
    JS += CoffeeScript.compile(cu_str, {});
    for (_k = 0, _len3 = files.length; _k < _len3; _k++) {
      file_path = files[_k];
      if (file_path == null) throw "File not found under '/client'!\n";
      app_file_path = file_path.remove(__dirname + '/client');
      log("Parsing file: " + app_file_path);
      _ref3 = app_file_path.toLowerCase().split(/\.|\//).last(2), file_name = _ref3[0], file_extension = _ref3[1];
      if ((templates[file_name] != null) && ['html', 'ck', 'templ', 'page'].has(file_extension)) {
        throw "\nERROR! Already has template with same name: " + file_name + ".html\n\n";
      }
      file_str = fs.readFileSync(file_path).toString();
      switch (file_extension) {
        case 'coffee':
          JS += "\n\n\n/* --- " + (app_file_path.toUpperCase()) + " --- */\n\n";
          JS += CoffeeScript.compile(file_str, {
            'filename': app_file_path
          });
          break;
        case 'less':
          (function() {
            var fname;
            fname = file_name;
            return LESS.render(file_str, less_options, function(e, css) {
              if (e) {
                log("------------------------------------------------------------\nERROR: " + fname + ".less: " + e.message + ": " + (e.extract.join('')) + "\n------------------------------------------------------------ ");
                throw "Less parsing failed";
              }
              CSS += "\n\n/* --- " + (fname.toUpperCase()) + ": --- */\n\n";
              CSS += css;
              log("              " + fname + ".less length: " + CSS.length);
              return fs.writeFileSync(__dirname + '/public/stylesheets/stylesheets.css', CSS, 'utf8', function(err) {
                if (err) throw err;
              });
            });
          })();
          break;
        case 'ccss':
          ccss_obj = eval(file_str);
          ccss_shortcuts(ccss_obj);
          try {
            ccss_css += ccss.compile;
          } catch (err) {
            log("\nERROR in compiling @style in template: " + file_name + "." + file_extension);
            throw err;
          }
          break;
        case 'templ':
        case 'page':
          try {
            templ_str = (CoffeeScript.compile(file_str, {})).replace(/\}\).call\(this\);\n$/, "return this;}).call({});");
            with( templ_helpers ){
            templates[file_name] = eval(templ_str);
          };
          } catch (err) {
            log("\nError in processing template: " + (file_name.toUpperCase()) + "." + (file_extension.toUpperCase()));
            log("" + err.stack);
            throw '';
          }
          if (templates[file_name].html == null) {
            err = "" + file_name + "." + file_extension + " is missing @html variable!\n";
            throw err;
          }
          if (file_extension === 'page' && !(templates[file_name].page != null)) {
            err = "" + file_name + ".page does not have @page variable! Use .templ extension if it's not a page.\n";
            throw err;
          } else if (file_extension === 'templ' && (templates[file_name].page != null)) {
            err = "" + file_name + ".templ has @page variable! You need to change it to .page -extension to keep things clear.\n";
            throw err;
          }
          if (templates[file_name].style != null) {
            ccss_shortcuts(templates[file_name].style);
            try {
              ccss_css += ccss.compile(templates[file_name].style);
            } catch (err) {
              log("\nERROR in compiling @style in template: " + file_name + "." + file_extension);
              throw err;
            }
            delete templates[file_name].style;
          }
          break;
        default:
          log("No action for " + app_file_path);
      }
    }
    /* Save coffee files client.js
    */
    fs.writeFileSync(__dirname + '/public/client_app.js', JS, 'utf8', function(err) {
      if (err) throw err;
    });
    /* Save ccss/css from templates
    */
    fs.writeFileSync(__dirname + '/public/stylesheets/templ_styles.css', ccss_css, 'utf8');
    /* compile preload.s.coffee
    */
    /* /client/index.ck -> /public/index.html
    */
    houce.compile_index();
    /* Manifest file
    */
    houce.create_manifest();
    /* Save templates to templates.js
    */
    stringify = function(main_obj) {
      var obj_strings;
      switch (typeof main_obj) {
        case 'object':
          if (main_obj === null) return 'null';
          obj_strings = [];
          main_obj.each(function(name, obj) {
            return obj_strings.push("'" + name + "': " + (stringify(obj)));
          });
          return "{ " + (obj_strings.join(',\n')) + " }";
        case 'function':
          return main_obj.toString();
        case 'string':
          return "'" + main_obj + "'";
        case 'number':
          return main_obj;
        case 'undefined':
          return 'undefined';
        default:
          throw "" + (typeof main_obj) + "'s not valid objects!";
      }
    };
    full_templ_str = "window.Templates = \n" + (stringify(templates)) + ";";
    fs.writeFileSync(__dirname + '/public/templates.js', full_templ_str, 'utf8', function(err) {
      if (err) throw err;
    });
    return console.info("Client files built!");
  });

  /* Pull new version of houCe from github
  */

  task('update_houce', function() {
    return exec("git pull git://github.com/jussiry/houCe.git", function(err, stdout, stderr) {
      if (err) {
        return console.log(err);
      } else {
        return console.log(stdout);
      }
    });
  });

  task('build_docs', function() {
    return exec("./node_modules/.bin/docco-husky start.coffee client common server", function(err, stdout, stderr) {
      if (err) {
        return console.log(err);
      } else {
        return console.log(stdout);
      }
    });
  });

  task('docs_to_github', function() {
    var log;
    log = function(m) {
      return console.log(m);
    };
    return exec("git branch -D gh-pages", function(err, stdout, stderr) {
      return exec("git symbolic-ref HEAD refs/heads/gh-pages", function(err, stdout, stderr) {
        if (err) return log(err);
        return exec("cake 'build_docs'", function(err, stdout, stderr) {
          if (err) return log(err);
          log("docs built");
          return exec("rm -R client common public server", function(err, stdout, stderr) {
            if (err) return log(err);
            log("code removed");
            return exec("mv ./public/docs/** .", function(err, stdout, stderr) {
              if (err) return log(err);
              log("docs moved/linked");
              return exec("git add .", function(err, stdout, stderr) {
                if (err) return log(err);
                log("git add done");
                return exec("git commit -a -m 'Docs updated'", function(err, stdout, stderr) {
                  if (err) return log(err);
                  log("git commit done");
                  return exec("git push -f origin gh-pages", function(err, stdout, stderr) {
                    if (err) return log(err);
                    log("git push done");
                    return exec("git checkout master", function(err, stdout, stderr) {
                      if (err) return log(err);
                      return log("Done. Will take a while for http://jussiry.github.com/houCe to be refreshed.");
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
  });

}).call(this);
