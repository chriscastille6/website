---
title: Contact
date: 2022-10-24

type: landing

sections:
  - block: markdown
    content:
      title: Contact
      text: |-
        ## Get in Touch
        
        Welcome! I'd love to hear from students, colleagues, and industry partners who are interested in people analytics, research collaboration, or learning more about evidence-based management.

        ### Contact Information
        
        **📧 Email:** [christopher.castille@nicholls.edu](mailto:christopher.castille@nicholls.edu)  
        **📞 Phone:** [985-449-7015](tel:985-449-7015)  
        **📍 Office:** Powell Hall, Room 150  
        **🏫 Address:** 906 East 1st St., College of Business Administration, Thibodaux, LA 70301  
        
        
        ### Campus Location
        
        My office is located in Powell Hall, Room 150, on the Nicholls State University campus in Thibodaux, Louisiana. The campus is easily accessible and visitor parking is available.
        
        ---
        
        **Contact Form**
        
        Feel free to use the form below to get in touch:
        
        <form name="contact" method="POST" data-netlify="true" action="/thank-you" netlify-honeypot="bot-field" class="mt-4">
          <p class="d-none">
            <label>Don't fill this out if you're human: <input name="bot-field" /></label>
          </p>
          <input type="hidden" name="form-name" value="contact" />
          
          <div class="form-group mb-3">
            <label for="name" class="form-label">Name *</label>
            <input type="text" name="name" class="form-control" id="name" required>
          </div>
          
          <div class="form-group mb-3">
            <label for="email" class="form-label">Email *</label>
            <input type="email" name="email" class="form-control" id="email" required>
          </div>
          
          <div class="form-group mb-3">
            <label for="subject" class="form-label">Subject *</label>
            <input type="text" name="subject" class="form-control" id="subject" required>
          </div>
          
          <div class="form-group mb-3">
            <label for="message" class="form-label">Message *</label>
            <textarea name="message" class="form-control" id="message" rows="5" required placeholder="Tell me about your interest in people analytics, research collaboration, or any questions you have..."></textarea>
          </div>
          
          <button type="submit" class="btn btn-primary px-4 py-2">Send Message</button>
        </form>

        <script>
          // Local development form handling
          document.addEventListener('DOMContentLoaded', function() {
            const form = document.querySelector('form[name="contact"]');
            if (form && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')) {
              form.addEventListener('submit', function(e) {
                e.preventDefault();
                alert('Message sent! (This is a local development simulation)');
                form.reset();
              });
            }
          });
        </script>
    design:
      columns: '1'
---
